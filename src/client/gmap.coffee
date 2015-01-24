_ = require 'lodash'

keys = require '../config/keys'

React = require "react/addons"

smoothPoints = (startPoint, endPoint) ->
    #return [endPoint]
    totalLatDist = endPoint.latitude - startPoint.latitude
    totalLongDist = endPoint.longitude - startPoint.longitude

    totalDist = Math.sqrt (Math.pow(totalLatDist, 2) + Math.pow(totalLongDist, 2))

    # Calculate minZoom for close together points.
    logDist = Math.log2 totalDist
    minZoom = Math.min(
        Math.max(4, 9 - (Math.round logDist)),
        Math.min(startPoint.zoom, endPoint.zoom))

    maxZoom = 21

    curveFactor = 18 # Higher = zoom out quicker before panning

    # first collect which zoom levels we are interested in (includes source)

    _zooms = [startPoint.zoom .. minZoom]

    n = 3 #Math.max(0, (10 - (zooms.length * 2)))

    zooms = _zooms.concat((minZoom for z in [0 .. n])).concat [minZoom .. endPoint.zoom]

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

    # The delay between timeouts when animating map transitions
    ANIMATION_RATE_MS: 100

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
        markers: []
        gmaps_api_key: keys.gmaps
        gmaps_sensor: false

    dragMarkerEnd: (event) ->
        p =
            latitude: event.latLng.lat()
            longitude: event.latLng.lng()
            zoom: @state.map.getZoom()
        @smoothPan p

    zoomForBounds: (bounds) ->
        ne = bounds.getNorthEast()
        sw = bounds.getSouthWest()

        totalLatDist = sw.lat() - ne.lat()
        totalLongDist = sw.lng() - ne.lng()

        totalDist = Math.sqrt (Math.pow(totalLatDist, 2) + Math.pow(totalLongDist, 2))

        logDist = Math.log2 totalDist

        zoom = Math.ceil (9 - logDist)
        zoom

    smoothPan: (endPoint) ->
        intermediatePoints = smoothPoints @currentView(), endPoint

        for point, i in intermediatePoints
            sT = (point, i) =>
                timeoutId = setTimeout (=>
                    center = new google.maps.LatLng(point.latitude, point.longitude)
                    zoom = point.zoom
                    # Maybe triggering some sort of onStateChange is better?
                    @state.map.panTo center
                    @state.map.setZoom zoom
                ), i * @ANIMATION_RATE_MS
                @timeoutIds.push timeoutId
            sT point, i

    # update geo-encoded markers
    updateMarkers: (points) ->
        markers = @state.markers
        map = @state.map

        # remove everything
        markers.forEach (marker) ->
            marker.setMap null
            google.maps.event.clearListeners marker, 'dragend'

        @state.markers = []

        # add new markers
        points.forEach (point) =>
            location = new google.maps.LatLng(point.latitude, point.longitude)
            marker = new google.maps.Marker
                position: location
                map: map
                title: point.label
                draggable: point.draggable

            google.maps.event.addListener marker, 'dragend', @dragMarkerEnd

            markers.push marker

        @setState markers: markers

    render: ->
        style =
            width: @props.width
            height: @props.height
        # pac-input needs a wrapper otherwise GMaps interferes with React >
        <div style={style}>
            <div>
                <input
                    id="pac-input"
                    className={if @props.editable then "editable" else ""}
                    type="text"
                    placeholder="Search Box"
                />
            </div>
            <div id="_GMAP_HOLDER" style={style}></div>
        </div>

    componentDidMount: ->
        window.getPoint = @currentView

        @timeoutIds = [] # maybe should be state?

        window.mapLoaded = =>
            mapOptions =
                zoom: @props.view.zoom
                center: new google.maps.LatLng(@props.view.latitude, @props.view.longitude)
                mapTypeId: google.maps.MapTypeId.ROADMAP
                disableDefaultUI: true
                zoomControl: false
                panControl: false
            map = new google.maps.Map(document.getElementById('_GMAP_HOLDER'), mapOptions)

            input = document.getElementById 'pac-input'
            map.controls[google.maps.ControlPosition.TOP_LEFT].push input
            # Use Autocomplete over SearchBox to avoid 'ambigious' results like
            # 'Pizza places in new York'
            searchBox = new google.maps.places.Autocomplete input

            @setState
                map: map
                searchBox: searchBox
            @updateMarkers @props.markers

            google.maps.event.addListener map, 'dragstart', =>
                @clearTimeouts()

            google.maps.event.addListener map, 'bounds_changed', _.debounce (=>
                @state.searchBox.setBounds @state.map.getBounds()
                @props.mapMove @currentView()), Math.max(200, @ANIMATION_RATE_MS + 25)

            google.maps.event.addListener searchBox, 'place_changed', =>
                place = @state.searchBox.getPlace()
                if Object.keys(place).length is 1
                    # User pressed enter and so it only gave us their text...
                    aus = new google.maps.places.AutocompleteService()
                    request =
                        bounds: @state.map.getBounds()
                        input: place.name
                    aus.getPlacePredictions request, (places) =>
                        if places?.length > 0
                            ps = new google.maps.places.PlacesService @state.map
                            # nice consistent API google!
                            ps.getDetails {placeId: places[0].place_id}, @setSearchPlace
                else
                    @setSearchPlace place


        s = document.createElement("script")
        s.src = ("https://maps.googleapis.com/maps/api/js?" +
                    "key=" + @props.gmaps_api_key +
                    "&sensor=" + @props.gmaps_sensor +
                    "&callback=mapLoaded" +
                    "&libraries=places")
        document.head.appendChild s

    setSearchPlace: (placeResult) ->
        z =
            if placeResult.types?[0] is "street_address"
                16
            else if placeResult.geometry.viewport?
                @zoomForBounds placeResult.geometry.viewport
            else
                18

        p =
            latitude: placeResult.geometry.location.lat()
            longitude: placeResult.geometry.location.lng()
            zoom: z
        @smoothPan p

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
        @updateMarkers props.markers if props.markers?

        if not props.fromMap
            @smoothPan props.view

module.exports = Map
