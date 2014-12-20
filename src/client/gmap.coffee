_ = require 'lodash'

React = require "react/addons"

smoothPoints = (startPoint, endPoint) ->
    #return [endPoint]
    totalLatDist = endPoint.latitude - startPoint.latitude
    totalLongDist = endPoint.longitude - startPoint.longitude

    totalDist = Math.sqrt (Math.pow(totalLatDist, 2) + Math.pow(totalLongDist, 2))

    # Calculate minZoom for close together points.
    logDist = Math.log2 totalDist
    minZoom = Math.min(
        Math.max(4, 10 - (Math.round logDist)),
        Math.min(startPoint.zoom, endPoint.zoom))

    maxZoom = 21

    curveFactor = 16 # Higher = zoom out quicker before panning

    # first collect which zoom levels we are interested in (includes source)

    zooms = [startPoint.zoom .. minZoom].concat([minZoom, minZoom, minZoom, minZoom, minZoom]).concat [minZoom .. endPoint.zoom]

    transitions = (_.zip zooms, zooms[1..])[..zooms.length - 2]

    # calculate total weight to normalise again
    totalWeightedDistance = 0
    for t in transitions
        avgZoom = (t[0] + t[1]) / 2
        totalWeightedDistance += Math.pow (maxZoom - avgZoom), curveFactor

    points = []
    currentPoint = startPoint

    # generate intermediate points using weighting
    for t in transitions
        avgZoom = (t[0] + t[1]) / 2
        weight = Math.pow((maxZoom - avgZoom), curveFactor) / totalWeightedDistance
        currentPoint =
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


    getPoint: ->
        center = @state.map.getCenter()
        return {
            zoom: @state.map.getZoom()
            latitude: center.lat()
            longitude: center.lng()
        }

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
        window.getPoint = @getPoint

        @timeoutIds = [] # maybe should be state?

        window.mapLoaded = =>
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

    clearTimeouts: ->
        for timeoutId in @timeoutIds
            clearTimeout timeoutId

        @timeoutIds = []

    currentView: ->
        latitude: @state.map.getCenter().lat()
        longitude: @state.map.getCenter().lng()
        zoom: @state.map.getZoom()

    # update markers if needed
    componentWillReceiveProps: (props) ->
        @clearTimeouts()
        @updateMarkers props.points if props.points

        intermediatePoints = smoothPoints @currentView(), props.view

        for point, i in intermediatePoints
            sT = (point, i) =>
                timeoutId = setTimeout (=>
                    center = new google.maps.LatLng(point.latitude, point.longitude)
                    zoom = point.zoom
                    # Maybe triggering some sort of onStateChange is better?
                    @state.map.panTo center
                    @state.map.setZoom zoom
                ), i * 100
                @timeoutIds.push timeoutId
            sT point, i

        @prevView = props.view

module.exports = Map
