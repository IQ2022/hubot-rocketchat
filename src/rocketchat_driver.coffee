Asteroid = require 'asteroid'

# TODO:   need to grab these values from process.env[]

_msgsubtopic = 'messages'
_msgsublimit = 10   # this is not actually used right now
_messageCollection = 'rocketchat_message'

# driver specific to Rocketchat hubot integration
# plugs into generic rocketchatbotadapter

class RocketChatDriver
  constructor: (url, @logger) ->
    @asteroid = new Asteroid(url)

  joinRoom: (userid, uname, roomid) =>
    @logger.info "joined room"
    @asteroid.call('addUserToRoom', {uid:userid, username:uname, rid:roomid})

  sendMessage: (text, roomid) =>
    @logger.info "send message"
    @asteroid.call('sendMessage', {msg: text, rid: roomid})

  login: (username, password) =>
    @logger.info "login"
    # promise returned
    return @asteroid.loginWithPassword username, password

  prepMeteorSubscriptions: (data) =>
    # use data to cater for param differences - until we learn more
    #    data.uid
    #    data.roomid
    # return promise
    @logger.info "prepare meteor subscriptions"
    msgsub = @asteroid.subscribe _msgsubtopic, data.roomid, _msgsublimit
    @logger.info "data.roomid == #{data.roomid}"
    return msgsub.ready

  setupReactiveMessageList: (receiveMessageCallback) =>
    @logger.info "setup reactive message list"
    @messages = @asteroid.getCollection _messageCollection
    rQ = @messages.reactiveQuery {}
    rQ.on "change", (id) =>
      # awkward syntax due to asteroid limitations
      # - it ain't no minimongo cursor
      @logger.info "change received on ID " + id
      changedMsgQuery = @messages.reactiveQuery {"_id": id}
      if changedMsgQuery.result
        changedMsg = changedMsgQuery.result[0]
        if changedMsg and changedMsg.msg and changedMsg.msg != "..."
          receiveMessageCallback changedMsg

module.exports = RocketChatDriver
