React = require "react/addons"

Map = React.createClass

    # initialize local variables
    getInitialState: ->
        map: null
        markers: []


    # set some default values
    getDefaultProps: ->
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
                zoom: @props.zoom
                center: new google.maps.LatLng(@props.latitude, @props.longitude)
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

        center = new google.maps.LatLng(props.latitude, props.longitude)
        zoom = props.zoom

        @state.map.panTo center
        @state.map.setZoom zoom

module.exports = Map
