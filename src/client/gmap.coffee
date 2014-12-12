_ = require 'lodash'

React = require "react/addons"

smoothPoints = (startPoint, endPoint) ->
    # TODO: Will zoom out too far for close points.
    maxZoom = 21
    minZoom = 3

    curveFactor = 2.4 # Higher = zoom out quicker before panning

    # first collect which zoom levels we are interested in (includes source)

    zooms = [startPoint.zoom-1 .. minZoom].concat [minZoom+1 .. endPoint.zoom]

    transitions = (_.zip zooms, zooms[1..])[..zooms.length - 2]

    # calculate total weight to normalise again
    totalWeightedDistance = 0
    for t in transitions
        avgZoom = (t[0] + t[1]) / 2
        totalWeightedDistance += Math.pow curveFactor, maxZoom - avgZoom

    points = []
    currentPoint = startPoint

    totalLatDist = endPoint.latitude - startPoint.latitude
    totalLongDist = endPoint.longitude - startPoint.longitude

    # generate intermediate points using weighting
    for t in transitions
        avgZoom = (t[0] + t[1]) / 2
        weight = Math.pow(curveFactor, maxZoom - avgZoom) / totalWeightedDistance
        currentPoint =
            weight: weight
            zoom:t[1]
            latitude: currentPoint.latitude + totalLatDist * weight
            longitude: currentPoint.longitude + totalLongDist * weight
        points.push currentPoint

    points

Map = React.createClass

    # initialize local variables
    getInitialState: ->
        map: null
        markers: []


    # set some default values
    getDefaultProps: ->
        view:
            latitude: 0
            longitude: 0
            zoom: 2
        width: "100%"
        height: "100%"
        points: []
        gmaps_api_key: "AIzaSyA6JBkMIUrJt45TPCMbdgkITL3JTCbywks"
        gmaps_sensor: false


    # update geo-encoded markers
    updateMarkers: (points) ->
        markers = @state.markers
        map = @state.map

        # remove everything
        markers.forEach (marker) ->
            marker.setMap null

        @state.markers = []

        # add new markers
        points.forEach (point) ->
            location = new google.maps.LatLng(point.latitude, point.longitude)
            marker = new google.maps.Marker
                position: location
                map: map
                title: point.label

            markers.push marker

        @setState markers: markers

    render: ->
        style =
            width: @props.width
            height: @props.height

        <div style={style}></div>

    componentDidMount: ->
        window.mapLoaded = =>
            @prevView = @props.view
            mapOptions =
                zoom: @props.view.zoom
                center: new google.maps.LatLng(@props.view.latitude, @props.view.longitude)
                mapTypeId: google.maps.MapTypeId.ROADMAP
                disableDefaultUI: true
                zoomControl: false
                panControl: false
            map = new google.maps.Map(@getDOMNode(), mapOptions)
            @setState map: map
            @updateMarkers @props.points

        s = document.createElement("script")
        s.src = "https://maps.googleapis.com/maps/api/js?key=" + @props.gmaps_api_key + "&sensor=" + @props.gmaps_sensor + "&callback=mapLoaded"
        document.head.appendChild s

    # update markers if needed
    componentWillReceiveProps: (props) ->
        @updateMarkers props.points  if props.points

        intermediatePoints = smoothPoints @prevView, props.view

        console.table intermediatePoints

        # TODO: deal with multiple queued animations
        for point, i in intermediatePoints
            sT = (point, i) =>
                setTimeout (=>
                    center = new google.maps.LatLng(point.latitude, point.longitude)
                    zoom = point.zoom
                    @state.map.panTo center
                    @state.map.setZoom zoom
                    @prevView = point
                ), i * 150
            sT point, i

        @prevView = props.view

module.exports = Map
