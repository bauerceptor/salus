var mascotWaitsHandsRubTL, mascotWaitsMouthTL;
var mascotWaitsDimple = document.getElementById('mascot-waits-dimple');
var mascotWaitsSmile = document.getElementById('mascot-waits-smile');
var mascotWaitsTongue = document.getElementById('mascot-waits-tongue');
var mascotWaitsSleeveL = document.getElementById('mascot-waits-sleeve-l');
var mascotWaitsArmL = document.getElementById('mascot-waits-arm-l');
var mascotWaitsArmL2 = "M218.9,248.2C200,296.9,200,332.9,160,279.6";
var mascotWaitsHandL = document.getElementById('mascot-waits-hand-l');
var mascotWaitsSleeveR = document.getElementById('mascot-waits-sleeve-r');
var mascotWaitsArmR = document.getElementById('mascot-waits-arm-r');
var mascotWaitsArmR2 = "M280.6,256.2c-18,51-58.3,74.8-112.9,21.2";
var mascotWaitsHandR = document.getElementById('mascot-waits-hand-r');
var mascotWaitsHead = document.getElementById('mascot-waits-head');
var mascotWaitsHandShift = 2;

function initMascotWaitsAnimation() {
  TweenMax.set(mascotWaitsHandL, { x: -mascotWaitsHandShift, y: -mascotWaitsHandShift });
  TweenMax.set(mascotWaitsHandR, { x: mascotWaitsHandShift, y: mascotWaitsHandShift });
  TweenMax.set(mascotWaitsArmL, { morphSVG: mascotWaitsArmL2 });
  TweenMax.set(mascotWaitsSleeveL, { morphSVG: mascotWaitsArmL2 });
  TweenMax.set(mascotWaitsTongue, { opacity: 1, transformOrigin: "100% 0%", scaleX: 0, scaleY: 0 });

  mascotWaitsHandsRubTL = new TimelineMax({ paused: true, repeat: -1, repeatDelay: 0 });
  mascotWaitsHandsRubTL
    .to(mascotWaitsHandL, 0.25, { x: mascotWaitsHandShift, y: mascotWaitsHandShift }, "0")
    .to(mascotWaitsHandR, 0.25, { x: -mascotWaitsHandShift, y: -mascotWaitsHandShift }, "0")
    .to(mascotWaitsHandL, 0.25, { x: -mascotWaitsHandShift, y: -mascotWaitsHandShift }, "0.25")
    .to(mascotWaitsHandR, 0.25, { x: mascotWaitsHandShift, y: mascotWaitsHandShift }, "0.25")

    .to(mascotWaitsArmL, 0.25, { morphSVG: mascotWaitsArmL }, "0")
    .to(mascotWaitsSleeveL, 0.25, { morphSVG: mascotWaitsSleeveL }, "0")
    .to(mascotWaitsArmL, 0.25, { morphSVG: mascotWaitsArmL2 }, "0.25")
    .to(mascotWaitsSleeveL, 0.25, { morphSVG: mascotWaitsArmL2 }, "0.25")

    .to(mascotWaitsArmR, 0.25, { morphSVG: mascotWaitsArmR2 }, "0")
    .to(mascotWaitsSleeveR, 0.25, { morphSVG: mascotWaitsArmR2 }, "0")
    .to(mascotWaitsArmR, 0.25, { morphSVG: mascotWaitsArmR }, "0.25")
    .to(mascotWaitsSleeveR, 0.25, { morphSVG: mascotWaitsSleeveR }, "0.25");

  mascotWaitsMouthTL = new TimelineMax({ paused: true, repeat: -1, repeatDelay: 0 });
  mascotWaitsMouthTL
    .to(mascotWaitsTongue, 0.75, { y: 27, scaleX: 1, scaleY: 1, ease: Power1.easeOut }, "0")
    .to(mascotWaitsTongue, 1.5, { rotation: "-60deg", ease: Power1.easeInOut }, "0")
    .to(mascotWaitsTongue, 0.75, { y: -10, ease: Power1.easeInOut }, "0.75")
    .to(mascotWaitsTongue, 0.75, { x: 4, ease: Power1.easeIn }, "0.75")
    .set(mascotWaitsTongue, { x: 0, y: 0 }, "7");

  mascotWaitsHandsRubTL.timeScale(1.5);
  mascotWaitsHandsRubTL.play();
  mascotWaitsMouthTL.play();
}

function initMascotWaits() {
  if (typeof TweenMax !== 'undefined') {
    initMascotWaitsAnimation();
  }
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initMascotWaits);
} else {
  initMascotWaits();
}
