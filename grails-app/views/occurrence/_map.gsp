<%@ page contentType="text/html;charset=UTF-8" %>
<style type="text/css">

#leafletMap {
    cursor: pointer;
    font-size: 12px;
    line-height: 18px;
}

#leafletMap, input {
    margin: 0px;
}

.leaflet-control-layers-base  {
    font-size: 12px;
}

.leaflet-control-layers-base label,  .leaflet-control-layers-base input, .leaflet-control-layers-base button, .leaflet-control-layers-base select, .leaflet-control-layers-base textarea {
    margin:0px;
    height:20px;
    font-size: 12px;
    line-height:18px;
    width:auto;
}

.leaflet-control-layers {
    opacity:0.8;
    filter:alpha(opacity=80);
}

.leaflet-control-layers-overlays label {
    font-size: 12px;
    line-height: 18px;
    margin-bottom: 0px;
}

.leaflet-drag-target {
    line-height:18px;
    font-size: 12px;
}

i.legendColour {
    -webkit-background-clip: border-box;
    -webkit-background-origin: padding-box;
    -webkit-background-size: auto;
    background-attachment: scroll;
    background-clip: border-box;
    background-image: none;
    background-origin: padding-box;
    background-size: auto;
    display: inline-block;
    height: 12px;
    line-height: 12px;
    width: 14px;
    margin-bottom: -5px;
    margin-left:2px;
    margin-right:2px;
    opacity:1;
    filter:alpha(opacity=100);
}

i#defaultLegendColour {
    margin-bottom: -2px;
    margin-left: 2px;
    margin-right: 5px;
}

.legendTable {
    padding: 0px;
    margin: 0px;
}

a.colour-by-legend-toggle {
    color: #000000;
    text-decoration: none;
    cursor: auto;
    display: block;
    font-family: 'Helvetica Neue', Arial, Helvetica, sans-serif;
    font-size: 14px;
    font-style: normal;
    font-variant: normal;
    font-weight: normal;
    line-height: 18px;
    text-decoration: none solid rgb(0, 120, 168);
    padding:5px 10px 5px 10px;
}

</style>

<table id="mapLayerControls">
<tr>
    <td>
        <label for="colourBySelect">Colour by:&nbsp;</label>

        <div class="layerControls">
            <select name="colourFacets" id="colourBySelect">
                <option value="">None</option>
                <g:each var="facetResult" in="${facets}">
                    <g:set var="Defaultselected">
                        <g:if test="${defaultColourBy && facetResult.fieldName == defaultColourBy}">selected="selected"</g:if>
                    </g:set>
                    <g:if test="${facetResult.fieldResult.size() > 1}">
                        <option value="${facetResult.fieldName}" ${Defaultselected}>
                            <alatag:formatDynamicFacetName fieldName="${facetResult.fieldName}"/>
                        </option>
                    </g:if>
                </g:each>
            </select>
        </div>
    </td>
    <g:if test="${skin == 'avh'}">
        <td>
            <label for="envLyrList">Environmental layer:&nbsp;</label>

            <div class="layerControls">
                <select id="envLyrList">
                    <option value="">None</option>
                </select>
            </div>
        </td>
        </tr>
        <tr>
    </g:if>
    <td>
        <label for="sizeslider">Size:</label>
        <div class="layerControls">
            <span id="sizeslider-val">4</span>
        </div>
        <div id="sizeslider" style="width:100px;"></div>
    </td>
    <td class="pull-right">
        <g:if test="${grailsApplication.config.skin.useAlaSpatialPortal?.toBoolean()}">
            <g:set var='spatialPortalLink' value="${sr.urlParameters}"/>
            <g:set var='spatialPortalUrlParams' value="${grailsApplication.config.spatial.params}"/>
            <div id="downloadMaps" class="btn btn-small">
                <a id="spatialPortalLink"
                   href="${grailsApplication.config.spatial.baseUrl}${spatialPortalLink}${spatialPortalUrlParams}">View in spatial portal</a>
            </div>
        </g:if>
        <div id="downloadMaps" class="btn btn-small">
            <a href="#downloadMap" role="button" data-toggle="modal" class="tooltips" title="Download image file (single colour mode)">
                <i class="hide icon-download"></i> Download map</a>
        </div>
    </td>
</tr>
</table>

<div id="leafletMap" class="span12" style="height:600px;"></div>

<div id="template" style="display:none">
    <div class="colourbyTemplate">
        <a class="colour-by-legend-toggle colour-by-control" href="#" title="Map legend">Legend</a>
        <form class="leaflet-control-layers-list">
            <div class="leaflet-control-layers-overlays">
                <div style="overflow:auto; max-height:400px;">
                    <a href="#" class="hideColourControl pull-right" style="padding-left:10px;"><i class="icon-remove icon-grey"></i></a>
                    <table class="legendTable"></table>
                </div>
            </div>
        </form>
    </div>
</div>


<div id="recordPopup" style="display:none;">
    <a href="#">View records at this point</a>
</div>


<r:script>

//    var cmAttr = 'Map data &copy; 2011 OpenStreetMap contributors, Imagery &copy; 2011 CloudMade',
//            cmUrl = 'http://{s}.tile.cloudmade.com/${grailsApplication.config.map.cloudmade.key}/{styleId}/256/{z}/{x}/{y}.png';
    var mbAttr = 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, ' +
				'<a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
				'Imagery © <a href="http://mapbox.com">Mapbox</a>';
	var mbUrl = 'https://{s}.tiles.mapbox.com/v3/{id}/{z}/{x}/{y}.png';

    //var minimal = L.tileLayer(cmUrl, {styleId: 22677, attribution: cmAttr});
    var defaultBaseLayer = L.tileLayer(mbUrl, {id: 'examples.map-20v6611k', attribution: mbAttr});
    //var defaultBaseLayer = new L.Google('ROADMAP');

    var MAP_VAR = {
        map : null,
        mappingUrl : "${mappingUrl}",
        query : "${searchString}",
        queryDisplayString : "${queryDisplayString}",
        center: [-23.6,133.6],
        defaultLatitude : "${grailsApplication.config.map.defaultLatitude?:'-23.6'}",
        defaultLongitude : "${grailsApplication.config.map.defaultLongitude?:'133.6'}",
        defaultZoom : "${grailsApplication.config.map.defaultZoom?:'4'}",
        overlays : {},
        baseLayers : {
            "Minimal" : defaultBaseLayer,
            //"Night view" : L.tileLayer(cmUrl, {styleId: 999,   attribution: cmAttr}),
            "Road" :  new L.Google('ROADMAP'),
            "Terrain" : new L.Google('TERRAIN'),
            "Satellite" : new L.Google('HYBRID')
        },
        layerControl : null,
        currentLayers : [],
        additionalFqs : '',
        zoomOutsideScopedRegion: ${(grailsApplication.config.map.zoomOutsideScopedRegion == false || grailsApplication.config.map.zoomOutsideScopedRegion == "false") ? false : true}
    };

    var ColourByControl = L.Control.extend({
        options: {
            position: 'topright',
            collapsed: false
        },
        onAdd: function (map) {
            // create the control container with a particular class name
            var $controlToAdd = $('.colourbyTemplate').clone();
            var container = L.DomUtil.create('div', 'leaflet-control-layers');
            var $container = $(container);
            $container.attr("id","colourByControl");
            $container.attr('aria-haspopup', true);
            $container.html($controlToAdd.html());
            return container;
        }
    });

    function initialiseMap(){
        console.log("initialiseMap", MAP_VAR.map);
        if(MAP_VAR.map != null){
            return;
        }

        //initialise map
        MAP_VAR.map = L.map('leafletMap', {
            center: [MAP_VAR.defaultLatitude, MAP_VAR.defaultLongitude],
            zoom: MAP_VAR.defaultZoom,
            minZoom: 1,
            scrollWheelZoom: false,
            fullscreenControl: true,
            fullscreenControlOptions: {
                position: 'topleft'
            }
        });

        //add the default base layer
        MAP_VAR.map.addLayer(defaultBaseLayer);

        L.control.coordinates({position:"bottomleft", useLatLngOrder: true}).addTo(MAP_VAR.map); // coordinate plugin

        MAP_VAR.layerControl = L.control.layers(MAP_VAR.baseLayers, MAP_VAR.overlays, {collapsed:true, position:'topleft'});
        MAP_VAR.layerControl.addTo(MAP_VAR.map);

        addQueryLayer(true);

        MAP_VAR.map.addControl(new ColourByControl());

        L.Util.requestAnimFrame(MAP_VAR.map.invalidateSize, MAP_VAR.map, !1, MAP_VAR.map._container);

        $('#colourBySelect').change(function(e) {
            MAP_VAR.additionalFqs = '';
            addQueryLayer(true);
        });

        $('.colour-by-control').click(function(e){

            if($(this).parent().hasClass('leaflet-control-layers-expanded')){
                $(this).parent().removeClass('leaflet-control-layers-expanded');
                $('.colour-by-legend-toggle').show();
            } else {
                $(this).parent().addClass('leaflet-control-layers-expanded');
                $('.colour-by-legend-toggle').hide();
            }
            e.preventDefault();
            e.stopPropagation();
            return false;
        });

        $('#colourByControl').mouseover(function(e){
            MAP_VAR.map.dragging.disable();
            MAP_VAR.map.off('click', pointLookup);
        });

        $('#colourByControl').mouseout(function(e){
            MAP_VAR.map.dragging.enable();
            MAP_VAR.map.on('click', pointLookup);
        });

        $('.hideColourControl').click(function(e){
            $('#colourByControl').removeClass('leaflet-control-layers-expanded');
            $('.colour-by-legend-toggle').show();
            e.preventDefault();
            e.stopPropagation();
            return false;
        });

        $( "#sizeslider" ).slider({
            min:2,
            max:10,
            tooltip: 'hide'
        }).on('slideStop', function(ev){
            $('#sizeslider-val').html(ev.value);
            addQueryLayer(true);
        });

        fitMapToBounds(); // zoom map if points are contained within Australia
        drawCircleRadius(); // draw circle around lat/lon/radius searches

        //enable the point lookup - but still allow double clicks to propagate
        var clickCount = 0;
        MAP_VAR.recordList = new Array(); // store list of records for popup

        MAP_VAR.map.on('click', function(e) {
            clickCount += 1;
            if (clickCount <= 1) {
                setTimeout(function() {
                    if (clickCount <= 1) {
                        pointLookup(e);
                    }
                    clickCount = 0;
                }, 400);
            }
        });
    }

    /**
     * A tile layer to map colouring the dots by the selected colour.
     */
    function addQueryLayer(redraw){

        $.each(MAP_VAR.currentLayers, function(index, value){
            MAP_VAR.map.removeLayer(MAP_VAR.currentLayers[index]);
            MAP_VAR.layerControl.removeLayer(MAP_VAR.currentLayers[index]);
        });

        MAP_VAR.currentLayers = [];

        var colourByFacet = $('#colourBySelect').val();
        var pointSize = $('#sizeslider-val').html();

        var envProperty = "color:${grailsApplication.config.map.pointColour};name:circle;size:"+pointSize+";opacity:1"

        if(colourByFacet){
            envProperty = "colormode:" + colourByFacet +";name:circle;size:"+pointSize+";opacity:1"
        }

        var layer = L.tileLayer.wms(MAP_VAR.mappingUrl + "/webportal/wms/reflect" + MAP_VAR.query + MAP_VAR.additionalFqs, {
            layers: 'ALA:occurrences',
            format: 'image/png',
            transparent: true,
            attribution: "${grailsApplication.config.skin.orgNameLong}",
            bgcolor:"0x000000",
            outline:"true",
            ENV: envProperty
        });

        if(redraw){
             if(!colourByFacet){
                $('.legendTable').html('');
                addDefaultLegendItem("${grailsApplication.config.map.pointColour}");
             } else {
                //update the legend
                $('.legendTable').html('<tr><td>Loading legend....</td></tr>');
                $.ajax({
                    url: "${request.contextPath}/occurrence/legend" + MAP_VAR.query + "&cm=" + colourByFacet + "&type=application/json",
                    success: function(data) {
                        $('.legendTable').html('');

                        $.each(data, function(index, legendDef){
                            var legItemName = legendDef.name ? legendDef.name : 'Not specified';
                            addLegendItem(legItemName, legendDef.red,legendDef.green,legendDef.blue );
                        });

                        $('.layerFacet').click(function(e){
                            var controlIdx = 0;
                            MAP_VAR.additionalFqs = '';
                            $('#colourByControl').find('.layerFacet').each(function(idx, layerInput){
                                var include =  $(layerInput).is(':checked');

                                if(!include){
                                    MAP_VAR.additionalFqs = MAP_VAR.additionalFqs + '&HQ=' + controlIdx;
                                }
                                controlIdx = controlIdx + 1;
                                addQueryLayer(false);
                            });
                        });
                    }
                });
            }
        }
        MAP_VAR.layerControl.addOverlay(layer, 'Occurrences');
        MAP_VAR.map.addLayer(layer);
        MAP_VAR.currentLayers.push(layer);
    }

    function addDefaultLegendItem(pointColour){
        $(".legendTable")
            .append($('<tr>')
                .append($('<td>')
                    .append($('<i>')
                        .addClass('legendColour')
                        .attr('style', "background-color:#"+ pointColour + ";")
                        .attr('id', 'defaultLegendColour')
                    )
                    .append($('<span>')
                        .addClass('legendItemName')
                        .html("All records")
                    )
                )
        );
    }

    function addLegendItem(name, red, green, blue){
        var nameLabel = jQuery.i18n.prop(name);
        $(".legendTable")
            .append($('<tr>')
                .append($('<td>')
                    .append($('<input>')
                        .attr('type', 'checkbox')
                        .attr('checked', 'checked')
                        .attr('id', name)
                        .addClass('layerFacet')
                        .addClass('leaflet-control-layers-selector')
                    )
                )
                .append($('<td>')
                    .append($('<i>')
                        .addClass('legendColour')
                        .attr('style', "background-color:rgb("+ red +","+ green +","+ blue + ");")
                    )
                    .append($('<span>')
                        .addClass('legendItemName')
                        .html((nameLabel.indexOf("[") == -1) ? nameLabel : name)
                    )
                )
        );
    }

    function rgbToHex(redD, greenD, blueD){
        var red = parseInt(redD);
        var green = parseInt(greenD);
        var blue = parseInt(blueD);

        var rgb = blue | (green << 8) | (red << 16);
        return rgb.toString(16);
    }

    /**
     * Event handler for point lookup.
     * @param e
     */
    function pointLookup(e) {

        MAP_VAR.popup = L.popup().setLatLng(e.latlng);
        var radius = 0;
        var size = $('sizeslider-val').html();
        var zoomLevel = MAP_VAR.map.getZoom();
        switch (zoomLevel){
            case 0:
                radius = 800;
                break;
            case 1:
                radius = 400;
                break;
            case 2:
                radius = 200;
                break;
            case 3:
                radius = 100;
                break;
            case 4:
                radius = 50;
                break;
            case 5:
                radius = 25;
                break;
            case 6:
                radius = 20;
                break;
            case 7:
                radius = 7.5;
                break;
            case 8:
                radius = 3;
                break;
            case 9:
                radius = 1.5;
                break;
            case 10:
                radius = .75;
                break;
            case 11:
                radius = .25;
                break;
            case 12:
                radius = .15;
                break;
            case 13:
                radius = .1;
                break;
            case 14:
                radius = .05;
                break;
            case 15:
                radius = .025;
                break;
            case 16:
                radius = .015;
                break;
            case 17:
                radius = 0.0075;
                break;
            case 18:
                radius = 0.004;
                break;
            case 19:
                radius = 0.002;
                break;
            case 20:
                radius = 0.001;
                break;
        }

        if (size >= 5 && size < 8){
            radius = radius * 2;
        }
        if (size >= 8){
            radius = radius * 3;
        }

        MAP_VAR.popupRadius = radius;
        var mapQuery = MAP_VAR.query.replace(/&(?:lat|lon|radius)\=[\-\.0-9]+/g, ''); // remove existing lat/lon/radius params
        MAP_VAR.map.spin(true);

        $.ajax({
            url: MAP_VAR.mappingUrl + "/occurrences/info" + mapQuery,
            jsonp: "callback",
            dataType: "jsonp",
            data: {
                zoom: MAP_VAR.map.getZoom(),
                lat: e.latlng.lat,
                lon: e.latlng.lng,
                radius: radius,
                format: "json"
            },
            success: function(response) {
                //console.log(response);
                MAP_VAR.map.spin(false);

                if (response.occurrences && response.occurrences.length > 0) {

                    MAP_VAR.recordList = response.occurrences; // store the list of record uuids
                    MAP_VAR.popupLatlng = e.latlng; // store the coordinates of the mouse click for the popup

                    // Load the first record details into popup
                    insertRecordInfo(0);

                }
            },
            error: function() {
                MAP_VAR.map.spin(false);
            }
        });
    }

    /**
    * Populate the map popup with record details
    *
    * @param recordIndex
    */
    function insertRecordInfo(recordIndex) {
        //console.log("insertRecordInfo", recordIndex, MAP_VAR.recordList);
        var recordUuid = MAP_VAR.recordList[recordIndex];
        var $popupClone = $('.popupRecordTemplate').clone();
        MAP_VAR.map.spin(true);

        if (MAP_VAR.recordList.length > 1) {
            // populate popup header
            $popupClone.find('.multiRecordHeader').show();
            $popupClone.find('.currentRecord').html(recordIndex + 1);
            $popupClone.find('.totalrecords').html(MAP_VAR.recordList.length.toString().replace(/100/, '100+'));
            var occLookup = "&radius=" + MAP_VAR.popupRadius + "&lat=" + MAP_VAR.popupLatlng.lat + "&lon=" + MAP_VAR.popupLatlng.lng;
            $popupClone.find('a.viewAllRecords').attr('href', "${request.contextPath}/occurrences/search" + MAP_VAR.query.replace(/&(?:lat|lon|radius)\=[\-\.0-9]+/g, '') + occLookup);
            // populate popup footer
            $popupClone.find('.multiRecordFooter').show();
            if (recordIndex < MAP_VAR.recordList.length - 1) {
                $popupClone.find('.nextRecord a').attr('onClick', 'insertRecordInfo('+(recordIndex + 1)+'); return false;');
                $popupClone.find('.nextRecord a').removeClass('disabled');
            }
            if (recordIndex > 0) {
                $popupClone.find('.previousRecord a').attr('onClick', 'insertRecordInfo('+(recordIndex - 1)+'); return false;');
                $popupClone.find('.previousRecord a').removeClass('disabled');
            }
        }

        $popupClone.find('.recordLink a').attr('href', "${request.contextPath}/occurrences/" + recordUuid);

        // Get the current record details
        $.ajax({
            url: MAP_VAR.mappingUrl + "/occurrences/" + recordUuid + ".json",
            jsonp: "callback",
            dataType: "jsonp",
            success: function(record) {
                MAP_VAR.map.spin(false);

                if (record.raw) {
                    var displayHtml = "";

                    // catalogNumber
                    if(record.raw.occurrence.catalogNumber != null){
                        displayHtml += "${g.message(code:'record.catalogNumber.label', default: 'Catalogue number')}: " + record.raw.occurrence.catalogNumber + '<br />';
                    } else if(record.processed.occurrence.catalogNumber != null){
                        displayHtml += "${g.message(code:'record.catalogNumber.label', default: 'Catalogue number')}: " + record.processed.occurrence.catalogNumber + '<br />';
                    }

                    if(record.raw.classification.vernacularName!=null ){
                        displayHtml += record.raw.classification.vernacularName + '<br />';
                    } else if(record.processed.classification.vernacularName!=null){
                        displayHtml += record.processed.classification.vernacularName + '<br />';
                    }

                    if (record.processed.classification.scientificName) {
                        displayHtml += formatSciName(record.processed.classification.scientificName, record.processed.classification.taxonRankID)  + '<br />';
                    } else {
                        displayHtml += record.raw.classification.scientificName  + '<br />';
                    }

                    if(record.processed.attribution.institutionName != null){
                        displayHtml += "${g.message(code:'record.institutionName.label', default: 'Institution')}: " + record.processed.attribution.institutionName + '<br />';
                    } else if(record.processed.attribution.dataResourceName != null){
                        displayHtml += "${g.message(code:'record.dataResourceName.label', default: 'Data Resource')}: " + record.processed.attribution.dataResourceName + '<br />';
                    }

                    if(record.processed.attribution.collectionName != null){
                        displayHtml += "${g.message(code:'record.collectionName.label', default: 'Collection')}: " + record.processed.attribution.collectionName  + '<br />';
                    }

                    if(record.raw.occurrence.recordedBy != null){
                        displayHtml += "${g.message(code:'record.recordedBy.label', default: 'Collector')}: " + record.raw.occurrence.recordedBy + '<br />';
                    } else if(record.processed.occurrence.recordedBy != null){
                        displayHtml += "${g.message(code:'record.recordedBy.label', default: 'Collector')}: " + record.processed.occurrence.recordedBy + '<br />';

                    }

                    if(record.processed.event.eventDate != null){
                        //displayHtml += "<br/>";
                        var label = "${g.message(code:'record.eventDate.label', default: 'Event date')}: ";
                        displayHtml += label + record.processed.event.eventDate;
                    }

                    $popupClone.find('.recordSummary').html( displayHtml ); // insert into clone
                } else {
                    // missing record - disable "view record" button and display message
                    $popupClone.find('.recordLink a').attr('disabled', true).attr('href','javascript: void(0)');
                    $popupClone.find('.recordSummary').html( "<br><g:message code="search.recordNotFoundForId" default="Error: record not found for ID:"/>: <span style='white-space:nowrap;'>" + recordUuid + '</span><br><br>' ); // insert into clone
                }

                MAP_VAR.popup.setContent($popupClone.html()); // push HTML into popup content
                MAP_VAR.popup.openOn(MAP_VAR.map);
            },
            error: function() {
                MAP_VAR.map.spin(false);
            }
        });

    }

    function getRecordInfo(){
        // http://biocache.ala.org.au/ws/occurrences/c00c2f6a-3ae8-4e82-ade4-fc0220529032
        //console.log("MAP_VAR.query", MAP_VAR.query);
        $.ajax({
            url: "${alatag.getBiocacheAjaxUrl()}/occurrences/info" + MAP_VAR.query,
            jsonp: "callback",
            dataType: "jsonp",
            success: function(response) {

            }
        });
    }

    /**
     * Format the display of a scientific name.
     * E.g. genus and below should be italicised
     */
    function formatSciName(name, rankId) {
        var output = "";
        if (rankId && rankId >= 6000) {
            output = "<i>" + name + "</i>";
        } else {
            output = name;
        }

        return output;
    }

    /**
     * Zooms map to either spatial search or from WMS data bounds
     */
    function fitMapToBounds() {
        // Don't run for spatial searches, which have their own fitBounds() method
        if (!isSpatialRadiusSearch()) {
            // all other searches (non-spatial)
            // do webservice call to get max extent of WMS data
            var jsonUrl = "${alatag.getBiocacheAjaxUrl()}/webportal/bounds.json" + MAP_VAR.query + "&callback=?";
            $.getJSON(jsonUrl, function(data) {
                if (data.length == 4) {
                    //console.log("data", data);
                    var sw = L.latLng(data[1],data[0]);
                    var ne = L.latLng(data[3],data[2]);
                    //console.log("sw", sw.toString());
                    var dataBounds = L.latLngBounds(sw, ne);
                    //var centre = dataBounds.getCenter();
                    var mapBounds = MAP_VAR.map.getBounds();

                    if (mapBounds && mapBounds.contains(sw) && mapBounds.contains(ne) && dataBounds) {
                        // data bounds is smaller than all of Aust
                        //console.log("smaller bounds",dataBounds,mapBounds)
                        MAP_VAR.map.fitBounds(dataBounds);

                        if (MAP_VAR.map.getZoom() > 15) {
                            MAP_VAR.map.setZoom(15);
                        }
                    } else if (MAP_VAR.zoomOutsideScopedRegion) {
                        // fitBounds is async so we set a one time only listener to detect change
                        MAP_VAR.map.once('zoomend', function() {
                            //console.log("zoomend", MAP_VAR.map.getZoom());
                            if (MAP_VAR.map.getZoom() < 2) {
                                MAP_VAR.map.setView(L.latLng(0, 24), 2); // zoom level 2 and centered over africa
                            }
                        });
                        MAP_VAR.map.fitBounds(dataBounds);
                    }
                    MAP_VAR.map.invalidateSize();
                }
            });
        }
    }

    /**
     * Spatial searches from Explore Your Area - draw a circle representing
     * the radius boundary for the search.
     *
     * Note: this function has a dependency on purl.js:
     * https://github.com/allmarkedup/purl
     */
    function drawCircleRadius() {
        if (isSpatialRadiusSearch()) {
            // spatial search from EYA
            var lat = $.url().param('lat');
            var lng = $.url().param('lon');
            var radius = $.url().param('radius');
            var latLng = L.latLng(lat, lng);
            var circleOpts = {
                weight: 1,
                color: 'white',
                opacity: 0.5,
                fillColor: '#222', // '#2C48A6'
                fillOpacity: 0.2
            }

            L.Icon.Default.imagePath = "${request.contextPath}/js/leaflet-0.7.2/images";
            var popupText = "Centre of spatial search with radius of " + radius + " km";
            var circle = L.circle(latLng, radius * 1030, circleOpts);
            circle.addTo(MAP_VAR.map);
            MAP_VAR.map.fitBounds(circle.getBounds()); // make circle the centre of the map, not the points
            L.marker(latLng, {title: popupText}).bindPopup(popupText).addTo(MAP_VAR.map);
            MAP_VAR.map.invalidateSize();
            //L.circleMarker(latLng, {radius: 6, opacity: 0.8, fillOpacity: 1.0}).bindPopup(popupText).addTo(MAP_VAR.map);
        }
    }

    /**
     * Returns true for a lat/lon/radius (params) style search
     *
     * @returns {boolean}
     */
    function isSpatialRadiusSearch() {
        var returnBool = false;
        var lat = $.url().param('lat');
        var lng = $.url().param('lon');
        var radius = $.url().param('radius');

        if (lat && lng && radius) {
            returnBool = true;
        }

        return returnBool
    }

</r:script>
<div class="hide">
    <div class="popupRecordTemplate">
        <div class="multiRecordHeader hide">
            <g:message code="search.map.viewing" default="Viewing"/> <span class="currentRecord"></span> <g:message code="search.map.of" default="of"/>
            <span class="totalrecords"></span> <g:message code="search.map.occurrences" default="occurrence records"/>
            &nbsp;&nbsp;<i class="icon-share-alt"></i> <a href="#" class="btn+btn-mini viewAllRecords"><g:message code="search.map.viewAllRecords" default="view all records"/></a>
        </div>
        <div class="recordSummary">

        </div>
        <div class="hide multiRecordFooter">
            <span class="previousRecord "><a href="#" class="btn btn-mini disabled" onClick="return false;"><g:message code="search.map.popup.prev" default="&lt; Prev"/></a></span>
            <span class="nextRecord "><a href="#" class="btn btn-mini disabled" onClick="return false;"><g:message code="search.map.popup.next" default="Next &gt;"/></a></span>
        </div>
        <div class="recordLink">
            <a href="#" class="btn btn-mini"><g:message code="search.map.popup.viewRecord" default="View record"/></a>
        </div>
    </div>
</div>
%{--<div style="display:none;">--}%
    %{--<div class="popupSingleRecordTemplate">--}%
        %{--<span class="dataResource">Dummy resource</span><br/>--}%
        %{--<span class="institution">Dummy institution</span><br/>--}%
        %{--<span class="collection">Dummy collection</span><br/>--}%
        %{--<span class="catalogueNumber">Dummy catalogue number</span><br/>--}%
        %{--<a href="" class="viewRecord">View this record</a>--}%
    %{--</div>--}%

    %{--<div class="popupMultiRecordTemplate">--}%
        %{--<span>Records: </span><a href="" class="viewAllRecords"><span class="recordCount">1,321</span></a><br/>--}%
        %{--<span class="dataResource">Dummy resource</span><br/>--}%
        %{--<span class="institution">Dummy institution</span><br/>--}%
        %{--<span class="collection">Dummy collection</span><br/>--}%
        %{--<span class="catalogueNumber">Dummy catalogue number</span><br/>--}%
        %{--<a href="" class="viewRecord" >View this record</a><br/>--}%
        %{--<a href="" class="viewAllRecords">View <span class="recordCount">1,321</span> records at this point</a>--}%
    %{--</div>--}%
%{--</div>--}%

<style type="text/css">
    /*#downloadMapForm { text-align:left; padding:0px; }*/
    /*#downloadMapForm fieldset p { padding-top:9px; }*/
    /*#downloadMapForm fieldset p input, #downloadMapForm fieldset p select { margin-left:15px; }*/
</style>

<div id="downloadMap" class="modal hide" tabindex="-1" role="dialog" aria-labelledby="downloadsMapLabel" aria-hidden="true">

    <form id="downloadMapForm">
        <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-hidden="true">×</button>
            <h3 id="downloadsMapLabel">Download publication map</h3>
        </div>
        <div class="modal-body">
            <input id="mapDownloadUrl" type="hidden" value="${alatag.getBiocacheAjaxUrl()}/webportal/wms/image"/>
            <fieldset>
                <p><label for="format">Format</label>
                    <select name="format" id="format">
                        <option value="jpg">JPEG</option>
                        <option value="png">PNG</option>
                    </select>
                </p>
                <p>
                    <label for="dpi">Quality (DPI)</label>
                    <select name="dpi" id="dpi">
                        <option value="100">100</option>
                        <option value="300" selected="true">300</option>
                        <option value="600">600</option>
                    </select>
                </p>
                <p>
                    <label for="pradiusmm">Point radius (mm)</label>
                    <select name="pradiusmm" id="pradiusmm">
                        <option>0.1</option>
                        <option>0.2</option>
                        <option>0.3</option>
                        <option>0.4</option>
                        <option>0.5</option>
                        <option>0.6</option>
                        <option selected="true">0.7</option>
                        <option>0.8</option>
                        <option>0.9</option>
                        <option>1</option>
                        <option>2</option>
                        <option>3</option>
                        <option>4</option>
                        <option>5</option>
                        <option>6</option>
                        <option>7</option>
                        <option>8</option>
                        <option>9</option>
                        <option>10</option>
                    </select>
                </p>
                <p>
                    <label for="popacity">Opacity</label>
                    <select name="popacity" id="popacity">
                        <option>1</option>
                        <option>0.9</option>
                        <option>0.8</option>
                        <option selected="true">0.7</option>
                        <option>0.6</option>
                        <option>0.5</option>
                        <option>0.4</option>
                        <option>0.3</option>
                        <option>0.2</option>
                        <option>0.1</option>
                    </select>
                </p>
                <p id="colourPickerWrapper">
                    <label for="pcolour">Color</label>
                    <%--<input type="text" name="pcolour" id="pcolour" value="0000FF" size="6"  />--%>
                    <select name="pcolour" id="pcolour">
                        <option value="ffffff">#ffffff</option>
                        <option value="ffccc9">#ffccc9</option>
                        <option value="ffce93">#ffce93</option>
                        <option value="fffc9e">#fffc9e</option>
                        <option value="ffffc7">#ffffc7</option>
                        <option value="9aff99">#9aff99</option>
                        <option value="96fffb">#96fffb</option>
                        <option value="cdffff">#cdffff</option>
                        <option value="cbcefb">#cbcefb</option>
                        <option value="cfcfcf">#cfcfcf</option>
                        <option value="fd6864">#fd6864</option>
                        <option value="fe996b">#fe996b</option>
                        <option value="fffe65">#fffe65</option>
                        <option value="fcff2f">#fcff2f</option>
                        <option value="67fd9a">#67fd9a</option>
                        <option value="38fff8">#38fff8</option>
                        <option value="68fdff">#68fdff</option>
                        <option value="9698ed">#9698ed</option>
                        <option value="c0c0c0">#c0c0c0</option>
                        <option value="fe0000">#fe0000</option>
                        <option value="f8a102">#f8a102</option>
                        <option value="ffcc67">#ffcc67</option>
                        <option value="f8ff00">#f8ff00</option>
                        <option value="34ff34">#34ff34</option>
                        <option value="68cbd0">#68cbd0</option>
                        <option value="34cdf9">#34cdf9</option>
                        <option value="6665cd">#6665cd</option>
                        <option value="9b9b9b">#9b9b9b</option>
                        <option value="cb0000">#cb0000</option>
                        <option value="f56b00">#f56b00</option>
                        <option value="ffcb2f">#ffcb2f</option>
                        <option value="ffc702">#ffc702</option>
                        <option value="32cb00">#32cb00</option>
                        <option value="00d2cb">#00d2cb</option>
                        <option value="3166ff">#3166ff</option>
                        <option value="6434fc">#6434fc</option>
                        <option value="656565">#656565</option>
                        <option value="9a0000">#9a0000</option>
                        <option value="ce6301">#ce6301</option>
                        <option value="cd9934">#cd9934</option>
                        <option value="999903">#999903</option>
                        <option value="009901">#009901</option>
                        <option value="329a9d">#329a9d</option>
                        <option value="3531ff" selected="selected">#3531ff</option>
                        <option value="6200c9">#6200c9</option>
                        <option value="343434">#343434</option>
                        <option value="680100">#680100</option>
                        <option value="963400">#963400</option>
                        <option value="986536">#986536</option>
                        <option value="646809">#646809</option>
                        <option value="036400">#036400</option>
                        <option value="34696d">#34696d</option>
                        <option value="00009b">#00009b</option>
                        <option value="303498">#303498</option>
                        <option value="000000">#000000</option>
                        <option value="330001">#330001</option>
                        <option value="643403">#643403</option>
                        <option value="663234">#663234</option>
                        <option value="343300">#343300</option>
                        <option value="013300">#013300</option>
                        <option value="003532">#003532</option>
                        <option value="010066">#010066</option>
                        <option value="340096">#340096</option>
                    </select>
                </p>
                <p>
                    <label for="widthmm">Width (mm)</label>
                    <input type="text" name="widthmm" id="widthmm" value="150" />
                </p>
                <p>
                    <label for="scale_on">Include scale</label>
                    <input type="radio" name="scale" value="on" id="scale_on" checked="checked"/> Yes &nbsp;
                    <input type="radio" name="scale" value="off" /> No
                </p>
                <p>
                    <label for="outline">Outline points</label>
                    <input type="radio" name="outline" value="true" id="outline" checked="checked"/> Yes &nbsp;
                    <input type="radio" name="outline" value="false" /> No
                </p>
                <p>
                    <label for="baselayer">Base layer</label>
                    <select name="baselayer" id="baselayer">
                        <option value="world">World outline</option>
                        <option value="aus1" selected="true">States & Territories</option>
                        <option value="aus2">Local government areas</option>
                        <option value="ibra_merged">IBRA</option>
                        <option value="ibra_sub_merged">IBRA sub regions</option>
                        <option value="imcra4_pb">IMCRA</option>
                    </select>
                </p>
                <p>
                    <label for="fileName">File name (without extension)</label>
                    <input type="text" name="fileName" id="fileName" value="MyMap"/>
                </p>
            </fieldset>

        </div>
        <div class="modal-footer">
            <button id="submitDownloadMap" class="btn" style="float:left;">Download map</button>
            <button class="btn" data-dismiss="modal" aria-hidden="true">Close</button>
        </div>
    </form>
</div>

<r:require module="colourPicker"/>
%{--<link rel="stylesheet" href="${request.contextPath}/css/jquery.colourPicker.css" type="text/css" media="screen" />--}%
%{--<script type="text/javascript" src="${request.contextPath}/static/js/jquery.colourPicker.js"></script>--}%
<script type="text/javascript">

    $(document).ready(function(){
        $('#pcolour').colourPicker({
            ico:    '${r.resource(dir:'images',file:'jquery.colourPicker.gif', plugin:'biocache-hubs')}',//'${request.contextPath}/static/images/jquery.colourPicker.gif',
            title:    false
        });
    });

    $('#submitDownloadMap').click(function(e){
        e.preventDefault();
        downloadMapNow();
    });

    function downloadMapNow(){

        var bounds = MAP_VAR.map.getBounds();
        var ne =  bounds.getNorthEast();
        var sw =  bounds.getSouthWest();
        var extents = sw.lng + ',' + sw.lat + ',' + ne.lng + ','+ ne.lat;

        var downloadUrl =  $('#mapDownloadUrl').val() +
                '${raw(sr.urlParameters)}' +
            //'&extents=' + '142,-45,151,-38' +  //need to retrieve the
                '&extents=' + extents +  //need to retrieve the
                '&format=' + $('#format').val() +
                '&dpi=' + $('#dpi').val() +
                '&pradiusmm=' + $('#pradiusmm').val() +
                '&popacity=' + $('#popacity').val() +
                '&pcolour=' + $(':input[name=pcolour]').val().toUpperCase() +
                '&widthmm=' + $('#widthmm').val() +
                '&scale=' + $(':input[name=scale]:checked').val() +
                '&outline=' + $(':input[name=outline]:checked').val() +
                '&outlineColour=0x000000' +
                '&baselayer=' + $('#baselayer').val()+
                '&fileName=' + $('#fileName').val()+'.'+$('#format').val().toLowerCase();

        //console.log('downloadUrl', downloadUrl);
        $('#downloadMap').modal('hide');
        document.location.href = downloadUrl;
    }
</script>