// Under Construction Animation
// Requires: CreateJS (createjs) and GSAP (gsap) libraries
// Add to your layout or page: <script src="https://code.createjs.com/1.0.0/createjs.min.js"></script>
//                             <script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/gsap.min.js"></script>

var UnderConstruction = (function() {
  function init(canvasId) {
    if (typeof createjs === "undefined" || typeof gsap === "undefined") {
      console.warn("UnderConstruction: CreateJS or GSAP not loaded. Skipping animation.");
      return;
    }

    var stage = new createjs.Stage(canvasId);
    var spriteSheet, sprite, tl;
    var spriteImage = new Image();
    spriteImage.crossOrigin = "Anonymous";

    var spriteSheetData = {
      frames: [
        [0, 0, 0, 0],
        [0, 0, 264, 160],
        [264, 0, 264, 160],
        [528, 0, 264, 160],
        [792, 0, 264, 160],
        [0, 160, 264, 160],
        [264, 160, 264, 160],
        [528, 160, 264, 160],
        [792, 160, 264, 160],
        [0, 320, 264, 160],
        [264, 320, 264, 160],
        [528, 320, 264, 160],
        [792, 320, 264, 160],
        [0, 480, 264, 160]
      ],
      animations: {
        dig: {
          frames: [1,2,2,2,2,1,3,4,5,6,7,8,8,9,9,10,10,11,11,12,12,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,6,6,5,5,4,4,3,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
        }
      }
    };

    spriteImage.onload = function() {
      spriteSheetData.images = [spriteImage];
      spriteSheet = new createjs.SpriteSheet(spriteSheetData);
      sprite = new createjs.Sprite(spriteSheet);
      sprite.gotoAndStop("dig");
      stage.addChild(sprite);
      stage.update();

      tl = gsap.timeline({ paused: true, repeat: -1, defaults: { ease: "none" } });
      tl.to(sprite, {
        currentAnimationFrame: gsap.utils.snap(1, spriteSheetData.animations["dig"].frames.length),
        duration: 2.5
      });

      tl.eventCallback("onUpdate", function() {
        stage.update();
      });

      tl.play();
    };

    spriteImage.src = "https://assets.codepen.io/128542/construction.png?v2";
  }

  return { init: init };
})();

// Auto-initialize when DOM is ready
document.addEventListener("DOMContentLoaded", function() {
  if (document.getElementById("constructionCanvas")) {
    UnderConstruction.init("constructionCanvas");
  }
});
