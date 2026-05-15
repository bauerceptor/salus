// Segmented Slider Control Component
// Handles the sliding animation for segmented controls

var SliderControl = (function() {
  function init(groupId) {
    var group = document.querySelector("#" + groupId + " .slider-control__options");
    if (!group) return;

    var radios = group.querySelectorAll(".slider-control__input");
    var i = 1;

    group.style.setProperty("--options", radios.length);

    radios.forEach(function(input) {
      input.setAttribute("data-pos", i);

      input.addEventListener("click", function(e) {
        group.style.setProperty("--options-active", e.target.getAttribute("data-pos"));
      });

      i++;
    });

    group.classList.add("useSlidingAnimation");
  }

  function initAll() {
    var groups = document.querySelectorAll(".slider-control__options");
    groups.forEach(function(group) {
      var radios = group.querySelectorAll(".slider-control__input");
      var i = 1;

      group.style.setProperty("--options", radios.length);

      radios.forEach(function(input) {
        input.setAttribute("data-pos", i);

        input.addEventListener("click", function(e) {
          group.style.setProperty("--options-active", e.target.getAttribute("data-pos"));
        });

        i++;
      });

      group.classList.add("useSlidingAnimation");
    });
  }

  document.addEventListener("DOMContentLoaded", function() {
    initAll();
  });

  return { init: init, initAll: initAll };
})();
