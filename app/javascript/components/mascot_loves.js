var mascotLovesKissTL;
var mascotLovesMouthDimple = document.getElementById('mascot-loves-mouth-dimple');
var mascotLovesMouthSmile = document.getElementById('mascot-loves-mouth-smile');
var mascotLovesMouthKissTop = document.getElementById('mascot-loves-mouth-kiss-top');
var mascotLovesMouthKissBot = document.getElementById('mascot-loves-mouth-kiss-bot');
var mascotLovesMouthOpen = document.getElementById('mascot-loves-mouth-open');
var mascotLovesArmL = document.getElementById('mascot-loves-arm-l');
var mascotLovesArmLEnd = "M218.9,247.2c-26,21.1-89.5,87.1-75.3-24.8";
var mascotLovesArmLUp = "M218.9,247.2c-49.4,26.2-105,10.3-119-63.9";
var mascotLovesSleeveL = document.getElementById('mascot-loves-sleeve-l');
var mascotLovesHandLThumb = document.getElementById('mascot-loves-hand-l-thumb');
var mascotLovesHandLIndex = document.getElementById('mascot-loves-hand-l-index');
var mascotLovesHandLMiddle = document.getElementById('mascot-loves-hand-l-middle');
var mascotLovesHandLPinky = document.getElementById('mascot-loves-hand-l-pinky');
var mascotLovesHandLThumbPathEnd = "M143.5,221.7c8.9,4.5,19.4,1.5,17.2-10";
var mascotLovesHandLIndexPathEnd = "M141.3,220.3c-10.3-13.3,5.6-28.9,15.6-18.2";
var mascotLovesHandLMiddlePathEnd = "M141.3,220.3c-7-6.1-4.3-20.5,10.2-16.5";
var mascotLovesHandLPinkyPathEnd = "M141.3,220.3c-7-6.1-4.3-20.5,10.2-16.5";
var mascotLovesHandLThumbPathUp = "M102.4,184.3c-0.9-8.1,2.5-20.3,15.7-20.3";
var mascotLovesHandLIndexPathUp = "M98.8,182.3c0.9-11.7-3.9-25.9-15.3-34.9";
var mascotLovesHandLMiddlePathUp = "M97.5,182.3c-4.7-9.6-10-19.4-20-24.1";
var mascotLovesHandLPinkyPathUp = "M96.9,182.3c-4.9-4.6-10.8-11-21.7-12.1";
var mascotLovesPops = document.querySelectorAll('#mascot-loves-pop path');

function initMascotLovesAnimation() {
  TweenMax.set(mascotLovesMouthSmile, { transformOrigin: "0% 50%" });
  TweenMax.set(mascotLovesMouthKissTop, { transformOrigin: "100% 100%", opacity: 1, scale: 0 });
  TweenMax.set(mascotLovesMouthKissBot, { transformOrigin: "100% 43%", opacity: 1, scale: 0 });
  TweenMax.set(mascotLovesMouthOpen, { transformOrigin: "89% 73%", opacity: 1, scale: 0 });
  TweenMax.set(mascotLovesPops, { opacity: 1, drawSVG: "0% 0%", opacity: 0.5 });

  mascotLovesKissTL = new TimelineMax({ paused: true, repeat: -1, repeatDelay: 1 });
  mascotLovesKissTL
    .to(mascotLovesMouthDimple, 0.5, { x: -20, y: 35, rotation: "45deg", scale: 0, ease: Quad.easeOut }, "0")
    .to(mascotLovesMouthSmile, 0.5, { drawSVG: "0 0", ease: Quad.easeOut }, "0")
    .to([mascotLovesMouthKissTop, mascotLovesMouthKissBot], 0.4, { scale: 1, ease: Quad.easeOut }, "0.25")

    .to([mascotLovesArmL, mascotLovesSleeveL], 0.6, { morphSVG: mascotLovesArmLEnd, ease: Power2.easeOut }, "0.1")
    .to(mascotLovesHandLThumb, 0.6, { morphSVG: mascotLovesHandLThumbPathEnd, ease: Power2.easeOut }, "0.1")
    .to(mascotLovesHandLIndex, 0.6, { morphSVG: mascotLovesHandLIndexPathEnd, ease: Power2.easeOut }, "0.1")
    .to(mascotLovesHandLMiddle, 0.6, { morphSVG: mascotLovesHandLMiddlePathEnd, ease: Power2.easeOut }, "0.1")
    .to(mascotLovesHandLPinky, 0.6, { morphSVG: mascotLovesHandLPinkyPathEnd, ease: Power2.easeOut }, "0.1")

    .to([mascotLovesArmL, mascotLovesSleeveL], 0.4, { morphSVG: mascotLovesArmLUp, ease: Power4.easeIn }, "1")
    .to(mascotLovesHandLThumb, 0.4, { morphSVG: mascotLovesHandLThumbPathUp, ease: Power4.easeIn }, "1")
    .to(mascotLovesHandLIndex, 0.4, { morphSVG: mascotLovesHandLIndexPathUp, ease: Power4.easeIn }, "1")
    .to(mascotLovesHandLMiddle, 0.4, { morphSVG: mascotLovesHandLMiddlePathUp, ease: Power4.easeIn }, "1")
    .to(mascotLovesHandLPinky, 0.4, { morphSVG: mascotLovesHandLPinkyPathUp, ease: Power4.easeIn }, "1")

    .to(mascotLovesPops, 0.1, { drawSVG: "0% 50%", ease: Linear.easeNone }, "1.3")
    .to(mascotLovesPops, 0.2, { drawSVG: "100% 110%", ease: Power1.easeOut }, "1.4")

    .to([mascotLovesMouthKissTop, mascotLovesMouthKissBot], 0.1, { scale: 0, ease: Linear.easeNone }, "1.3")
    .to(mascotLovesMouthOpen, 0.3, { scale: 1, ease: Power2.easeOut }, "1.3")

    .to(mascotLovesMouthOpen, 0.25, { scale: 0, ease: Power2.easeIn }, "2")
    .to(mascotLovesMouthSmile, 0.5, { drawSVG: "0% 100%", ease: Power2.easeOut }, "2.25")
    .to(mascotLovesMouthDimple, 0.5, { x: 0, y: 0, rotation: "0deg", scale: 1, ease: Power2.easeOut }, "2.25")

    .to(mascotLovesArmL, 1, { morphSVG: mascotLovesArmL, ease: Power2.easeInOut }, "2.25")
    .to(mascotLovesSleeveL, 1, { morphSVG: mascotLovesSleeveL, ease: Power2.easeInOut }, "2.25")
    .to(mascotLovesHandLThumb, 1, { morphSVG: mascotLovesHandLThumb, ease: Power2.easeInOut }, "2.25")
    .to(mascotLovesHandLIndex, 1, { morphSVG: mascotLovesHandLIndex, ease: Power2.easeInOut }, "2.25")
    .to(mascotLovesHandLMiddle, 1, { morphSVG: mascotLovesHandLMiddle, ease: Power2.easeInOut }, "2.25")
    .to(mascotLovesHandLPinky, 1, { morphSVG: mascotLovesHandLPinky, ease: Power2.easeInOut }, "2.25")

    .set(mascotLovesPops, { drawSVG: "-10% 0%", ease: Linear.easeNone }, "2.5");
}

function initMascotLoves() {
  if (typeof TweenMax !== 'undefined') {
    initMascotLovesAnimation();
    mascotLovesKissTL.play();
  }
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initMascotLoves);
} else {
  initMascotLoves();
}
