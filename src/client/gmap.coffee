React = require "react/addons"

smoothPoints = (startPoint, endPoint) ->
    # TODO: Will zoom out too far for close points.
    # TODO: Weight should be based on before and after zoom, not just after.
    # TODO: Don't smove in highest level zoom.
    maxZoom = 21
    minZoom = 3

    curveFactor = 2.5 # Higher = zoom out quicker before panning

    zoomOut = startPoint.zoom - minZoom
    zoomIn = endPoint.zoom - minZoom

    totalWeightedDistance = 0
    for zoom in [startPoint.zoom-1 .. minZoom]
        console.log zoom
        totalWeightedDistance += Math.pow curveFactor, (maxZoom - zoom)

    for zoom in [endPoint.zoom .. minZoom]
        console.log zoom
        totalWeightedDistance += Math.pow curveFactor, (maxZoom - zoom)

    points = [startPoint]
    currentPoint = startPoint

    for zoom in [startPoint.zoom-1 .. minZoom]
        weight = Math.pow(curveFactor, (maxZoom - zoom)) / totalWeightedDistance
        currentPoint =
            weight: weight
            zoom:zoom
            latitude: currentPoint.latitude + (endPoint.latitude - startPoint.latitude) * weight
            longitude: currentPoint.longitude + (endPoint.longitude - startPoint.longitude) * weight
        points.push currentPoint

    for zoom in [minZoom .. endPoint.zoom]
        weight = Math.pow(curveFactor, (maxZoom - zoom)) / totalWeightedDistance
        currentPoint =
            weight: weight
            zoom: zoom
            latitude: currentPoint.latitude + (endPoint.latitude - startPoint.latitude) * weight
            longitude: currentPoint.longitude + (endPoint.longitude - startPoint.longitude) * weight
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

        center = new google.maps.LatLng(props.view.latitude, props.view.longitude)
        zoom = props.view.zoom

        @state.map.panTo center
        @state.map.setZoom zoom

module.exports = Map
