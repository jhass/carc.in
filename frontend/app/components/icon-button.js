import TooltipsterComponent from "ember-cli-tooltipster/components/tool-tipster";

export default TooltipsterComponent.extend({
    tagName: "a",
    position: "top",
    animation: "fade",
    theme: "tooltips",
    delay: 10,
    attributeBindings: ["href", "download", "target"],
    classNames: ["button"],
    classNameBindings: ["iconClass"],
    iconClass: function() {
      return ["icon-"+this.get("icon")];
    }.property("icon"),
    click: function() {
      this.sendAction();
    }
});
