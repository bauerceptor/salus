// Request Help Button Component
// Handles toggle functionality for the request help button

var RequestHelp = (function() {
  var helpButton;
  var helpButtonBounds;

  function helpButtonClick(e) {
    var pressedLabel = e.currentTarget.querySelector(".request-help__pressedLabel");
    var unpressedLabel = e.currentTarget.querySelector(".request-help__unpressedLabel");

    if (e.currentTarget.getAttribute("aria-pressed") == "true") {
      pressedLabel.classList.add("visuallyHidden");
      unpressedLabel.classList.remove("visuallyHidden");
      helpButton.setAttribute("aria-pressed", false);
    } else {
      pressedLabel.classList.remove("visuallyHidden");
      unpressedLabel.classList.add("visuallyHidden");
      helpButton.setAttribute("aria-pressed", true);
    }

    helpButtonUpdate();
  }

  function helpButtonUpdate() {
    var newBounds = helpButton.getBoundingClientRect();
    helpButton.style.setProperty("--w", newBounds.width);
    helpButtonBounds = newBounds;
  }

  function init() {
    helpButton = document.querySelector(".request-help__button");
    if (!helpButton) return;

    helpButtonBounds = helpButton.getBoundingClientRect();
    helpButtonUpdate();
    helpButton.addEventListener("click", helpButtonClick);
  }

  document.addEventListener("DOMContentLoaded", function() {
    init();
  });

  return { init: init };
})();
