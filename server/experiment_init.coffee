replaceURLWithHTMLLinks = (text) ->
  exp = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig
  text.replace(exp, "<a href='$1' target='_blank'>$1</a>")

loadDumbTweets = ->
  Assets.getText "tweets_raw_partial.txt", (err, res) ->
    throw err if err
    tweets = replaceURLWithHTMLLinks(res).split("\n")
    _.each tweets, (e, i) ->
      return unless e # Don't insert empty string
      Datastream.insert
        text: e
    console.log(tweets.length + " tweets inserted")

loadCSVTweets = (file, limit) ->
  # csv is exported by the csv package

  Assets.getText file, (err, res) ->
    throw err if err
    # TODO consider having the client do this
    tweets = replaceURLWithHTMLLinks(res)

    csv()
    .from.string(tweets, {
        columns: true
        trim: true
      })
    .to.array Meteor.bindEnvironment ( arr, count ) ->

      i = 0
      while i < limit and i < arr.length
        i++
        Datastream.insert
          num: i # Keeps things in time order
          text: arr[i].text
      # console.log(i + " tweets inserted")

    , (e) ->
      Meteor._debug "Exception while reading CSV:", e

TurkServer.initialize ->
  return if Datastream.find().count() > 0

  if @instance.treatment().tutorialEnabled
    loadCSVTweets("tutorial.csv", 10)
  else
    # Load initial tweets on first start
    # loadDumbTweets()
    loadCSVTweets("PabloPh_UN_cm.csv", 500)
    # Create a seed instructions document for the app
    docId = Meteor.call("createDocument", "Instructions")
    Assets.getText "seed-instructions.txt", (err, res) ->
      if err?
        console.log "Error getting document"
        return
      ShareJS.initializeDoc(docId, res)

TurkServer.onConnect ->
  if @instance.treatment().tutorialEnabled
    # Help the poor folks who shot themselves in the foot
    # TODO do a more generalized restore
    Datastream.update({}, {$unset: hidden: null}, {multi: true})
