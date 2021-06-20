var container = d3.select("div#container")
var svg = container.append("svg")
var group = svg.append('g')

var zoom = d3.behavior.zoom()
    .scaleExtent([0.1, 7])

var force = d3.layout.force()
    .gravity(.5)
    .distance(750)
    .charge(-5000)


var K = 20

initGraph()
initCheckbox()

function initSlider(container, oninput) {
    var slider_container = d3.select(container)
    var slider_label = slider_container.select('.value')
    slider_container.select('input')
        .on('input', function() {
            var value = d3.select(this).property('value') / 100.0
            force.stop()
            force.start()
            slider_label.text(oninput(value))
        })
}

function initCheckbox() {
    d3.select('#showLabels')
        .on('change', function() {
            var labelsVisible = d3.select(this).property('checked') ? true : false
            
            group.selectAll(".node text")
                .style('visibility', labelsVisible ? 'visible' : 'hidden')
        })

    initSlider(
        '#gravityRange',
        function(value) {
            force.gravity(value)
            return value
        }
    )

    initSlider(
        '#chargeRange',
        function(value) {
            var v = value * -5000
            force.charge(v)
            return v
        }
    )

    initSlider(
        '#chargeDistRange',
        function(value) {
            var v = value * 5000
            force.chargeDistance(v)
            return v
        }
    )

    initSlider(
        '#distanceRange',
        function(value) {
            var v = value * 5000
            force.distance(v)
            return v
        }
    )

    initSlider(
        '#kRange',
        function(value) {
            var v = value * 20
            K = v
            return v
        }
    )

}

function initGraph() {
    svg
        .call(zoom)

    resize()

    d3.select(window).on('resize', resize)

    zoom
        .on("zoom", function() {
            group.attr(
                "transform",
                "translate(" + d3.event.translate + ")" + " scale(" + d3.event.scale + ")"
            )
        })
}

function resize() {
    var width = container[0][0].clientWidth
    var height = container[0][0].clientHeight

    svg
      .attr("width", width)
      .attr("height", height);

    force .size([width, height])
}

function got_graph(json) {
    force
      .nodes(json.nodes)
      .links(json.links)
      .start();

    var link = group.selectAll(".link")
        .data(json.links)
        .enter()
            .append("line")
            .attr("class", "link")

    var node = group.selectAll(".node")
        .data(json.nodes)
        .enter()
            .append("g")
            .attr("class", "node")
            .call(force.drag)
            .on('mousedown', function() {
                d3.event.stopPropagation()
            })

    node.append("rect").attr('fill', 'blue')

    node
        .append("circle")
            .attr("r","5");

    node
        .append("text")
            //.attr("dx", 12)
            //.attr("dy", ".35em")
            .text(function(d) { return d.name })
            .each(function(d) { 
                d.bb = this.getBBox()
            })


    force.on("tick", function(e) {
        var k = K * e.alpha; // fa scendere

        link
            .each(function(d) { d.source.y += k; d.target.y -= k; })
            .attr("x1", function(d) { return d.source.x; })
            .attr("y1", function(d) { return d.source.y; })
            .attr("x2", function(d) { return d.target.x; })
            .attr("y2", function(d) { return d.target.y; });

        node
            .attr("transform", function(d) {
                return "translate(" + d.x + "," + d.y + ")";
            });

        node.select('text')
            .attr('x', function(d) { return - d.bb.width / 2.0 })
            .attr('y', function(d) { return d.bb.height / 2.0 })

        node.select('rect')
            .attr('x', function(d) { return -d.bb.width / 2.0 } )
            .attr('y', function(d) { return -d.bb.height / 2.0 } )
            .attr('width', function(d) { return d.bb.width } )
            .attr('height', function(d) { return d.bb.height } )
      });
}
