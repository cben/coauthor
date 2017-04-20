import { defaultFormat } from '../lib/settings.coffee'

Template.registerHelper 'defaultFormat', ->
  defaultFormat

Template.settings.onCreated ->
  @autorun ->
    setTitle 'Settings'

myAfter = (user) -> user.notifications?.after ? defaultNotificationDelays.after

Template.settings.helpers
  profile: -> Meteor.user().profile
  autopublish: autopublish
  notificationsOn: notificationsOn
  notificationsDefault: notificationsDefault
  notificationsAfter: ->
    after = myAfter @
    "#{after.after} #{after.unit}#{if after.after == 1 then '' else 's'}"
  activeNotificationAfter: (match) ->
    match = match.hash
    after = myAfter @
    if after.after == match.after and after.unit == match.unit
      'active'
    else
      ''
  notifySelf: notifySelf
  autosubscribeGroup: -> autosubscribe routeGroup()
  autosubscribeGlobal: -> autosubscribe wildGroup
  theme: -> capitalize theme()
  dropbox: ->
    'dropbox' of (Meteor.user().services ? {})

Template.settings.events
  'click .editorKeyboard': (e, t) ->
    e.preventDefault()
    e.stopPropagation()
    Meteor.users.update Meteor.userId(),
      $set: "profile.keyboard": e.target.getAttribute 'data-keyboard'
    dropdownToggle e

  'click .editorFormat': (e, t) ->
    e.preventDefault()
    e.stopPropagation()
    Meteor.users.update Meteor.userId(),
      $set: "profile.format": e.target.getAttribute 'data-format'
    dropdownToggle e

  'click .autopublishButton': (e, t) ->
    e.preventDefault()
    e.stopPropagation()
    Meteor.users.update Meteor.userId(),
      $set: "profile.autopublish": not autopublish()

  'click .notificationsButton': (e, t) ->
    e.preventDefault()
    e.stopPropagation()
    Meteor.users.update Meteor.userId(),
      $set: "profile.notifications.on": not notificationsOn()

  'click .notifySelfButton': (e, t) ->
    e.preventDefault()
    e.stopPropagation()
    Meteor.users.update Meteor.userId(),
      $set: "profile.notifications.self": not notifySelf()

  'click .notificationAfter': (e, t) ->
    e.preventDefault()
    e.stopPropagation()
    Meteor.users.update Meteor.userId(),
      $set: "profile.notifications.after":
        after: parseFloat e.target.getAttribute 'data-after'
        unit: e.target.getAttribute 'data-unit'
    dropdownToggle e

  'click .autosubscribeGlobalButton': (e, t) ->
    e.preventDefault()
    e.stopPropagation()
    Meteor.users.update Meteor.userId(),
      $set: "profile.notifications.autosubscribe.#{wildGroup}": not autosubscribe wildGroup

  'click .autosubscribeGroupButton': (e, t) ->
    e.preventDefault()
    e.stopPropagation()
    Meteor.users.update Meteor.userId(),
      $set: "profile.notifications.autosubscribe.#{escapeGroup routeGroup()}": not autosubscribe routeGroup()

  'click .themeButton': (e, t) ->
    e.preventDefault()
    e.stopPropagation()
    Meteor.users.update Meteor.userId(),
      $set: "profile.theme":
        if theme() == 'dark'
          'light'
        else
          'dark'

  'click .linkDropbox': (e, t) ->
    e.preventDefault()
    e.stopPropagation()
    Meteor.linkWithDropbox()

  'click .unlinkDropbox': (e, t) ->
    e.preventDefault()
    e.stopPropagation()
    Meteor.call '_accounts/unlink/service', Meteor.userId(), 'dropbox'

for template in [Template.fullNameEditor, Template.emailEditor]
  template.onCreated ->
    @editing = new ReactiveVar
    ## When active editor gets rendered (typically after clicking "Edit"),
    ## give it focus.
    @autorun =>
      if @editing.get()
        setTimeout =>
          $(@find '.textEdit').focus()
        , 100
  template.helpers
    editing: -> Template.instance().editing.get()
  template.events
    'click .editButton': (e, t) ->
      e.preventDefault()
      e.stopPropagation()
      t.editing.set true
  saveButton = (callback) -> (e, t) ->
    e.preventDefault()
    e.stopPropagation()
    value = t.find('.textEdit').value.trim()
    callback.call @, value
    t.editing.set false

Template.fullNameEditor.helpers
  fullname: -> @fullname
  showFullname: -> @fullname or "(not specified)"

Template.fullNameEditor.events
  'click .saveButton': saveButton (fullname) ->
    if fullname != @fullname
      Meteor.users.update Meteor.userId(),
        $set: 'profile.fullname': fullname

currentEmail = ->
  Meteor.user().emails?[0]?.address

Template.emailEditor.helpers
  email: currentEmail
  showEmail: -> currentEmail() or "(not specified)"

Template.emailEditor.events
  'click .saveButton': saveButton (email) ->
    if email != currentEmail()
      Meteor.call 'userEditEmail', email
