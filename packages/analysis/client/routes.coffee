# This controller handles the behavior of all admin templates
# TODO: it doesn't belong in the analysis package, but we use it here.
class AdminController extends RouteController
  onBeforeAction: ->
    unless TurkServer.isAdmin()
      @render("loadError")
    else
      @next()

# TODO fix hack below that is used to avoid hitting the server twice
# https://github.com/EventedMind/iron-router/issues/1011 and related
class AdminDataController extends AdminController
  waitOn: ->
    return if @data()?

    args = @route.options.methodArgs.call(this)
    console.log "getting data"

    # Tack on callback argument
    args.push (err, res) =>
      bootbox.alert(err) if err
      console.log "got data"
      @state.set("data", res)

    Meteor.call.apply(null, args)

    return => @data()?

  data: -> @state.get("data")

Router.map ->
  # Single-instance visualization templates
  @route 'viz',
    path: 'viz/:groupId'
    controller: AdminDataController
    methodArgs: -> [ "cm-get-viz-data", this.params.groupId ]

  # Overview route, with access to experiments and stuff
  @route 'overview',
    controller: AdminController
    layoutTemplate: "overviewLayout"

  @route 'overviewExperiments',
    path: 'overview/experiments'
    controller: AdminController
    layoutTemplate: "overviewLayout"
    waitOn: ->
      Meteor.subscribe("cm-analysis-worlds", {
        pseudo: null,
        synthetic: null
      })

  @route 'overviewPeople',
    path: 'overview/people'
    controller: AdminController
    layoutTemplate: "overviewLayout"
    waitOn: -> Meteor.subscribe("cm-analysis-people")

  @route 'overviewTagging',
    path: 'overview/tagging'
    controller: AdminDataController
    layoutTemplate: "overviewLayout"
    methodArgs: -> [ "cm-get-group-cooccurences" ]

  @route 'overviewStats',
    path: 'overview/stats'
    controller: AdminDataController
    layoutTemplate: "overviewLayout"
    methodArgs: -> [ "cm-get-action-weights" ]

  @route 'overviewGroupPerformance',
    path: 'overview/groupPerformance'
    controller: AdminController
    layoutTemplate: "overviewLayout"
    waitOn: ->
      Meteor.subscribe("cm-analysis-worlds")

  @route 'overviewGroupSlices',
    path: 'overview/groupSlices'
    controller: AdminController
    layoutTemplate: "overviewLayout"
    waitOn: ->
      Meteor.subscribe("cm-analysis-worlds", {
        pseudo: null,
        synthetic: null
      })

  @route 'overviewIndivPerformance',
    path: 'overview/indivPerformance'
    controller: AdminController
    layoutTemplate: "overviewLayout"
    waitOn: -> Meteor.subscribe("cm-analysis-people")

  @route 'overviewSpecialization',
    path: 'overview/specialization'
    controller: AdminController
    layoutTemplate: "overviewLayout"
    waitOn: ->
      Meteor.subscribe("cm-analysis-worlds", {
        pseudo: null,
        synthetic: null
      })