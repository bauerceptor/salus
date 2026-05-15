var mascotDeliversTL, mascotDeliversMouthTL;
var mascotDeliversDimple = document.getElementById('mascot-delivers-dimple');
var mascotDeliversMouth = document.getElementById('mascot-delivers-mouth');
var mascotDeliversArmL = document.getElementById('mascot-delivers-arm-l');
var mascotDeliversArmR = document.getElementById('mascot-delivers-arm-r');
var mascotDeliversHandR = document.getElementById('mascot-delivers-hand-r');
var mascotDeliversBox = document.getElementById('mascot-delivers-box');
var mascotDeliversBody = document.getElementById('mascot-delivers-body');
var mascotDeliversHead = document.getElementById('mascot-delivers-head');
var mascotDeliversMouth2 = "M213.2,181c1.3,2.5,4.3,3,7.2,1.5 c2.3-1.2,2.7-4.2,1.6-6.4c-1.1-2.2-3.7-3-5.6-2.1C213.1,175.5,211.7,178,213.2,181z";
var mascotDeliversNote1 = document.getElementById('mascot-delivers-note-1');
var mascotDeliversNote2 = document.getElementById('mascot-delivers-note-2');

function initMascotDeliversAnimation() {
  TweenMax.set(mascotDeliversArmL, { transformOrigin: "100% 0%" });
  TweenMax.set(mascotDeliversArmR, { transformOrigin: "0% 58%" });
  TweenMax.set(mascotDeliversBox, { rotation: "-2deg" });
  TweenMax.set(mascotDeliversBody, { transformOrigin: "0% 100%" });
  TweenMax.set(mascotDeliversDimple, { transformOrigin: "50% 50%" });
  TweenMax.set([mascotDeliversNote2, mascotDeliversNote1], { transformOrigin: "50% 50%", scaleX: 0, scaleY: 0 });

  mascotDeliversTL = new TimelineMax({ paused: true, repeat: -1, repeatDelay: 0 });
  mascotDeliversTL
    .to(mascotDeliversArmL, 0.6, { rotation: "-60deg", ease: Power2.easeInOut }, "0")
    .to(mascotDeliversArmL, 0.6, { rotation: "0deg", ease: Power2.easeInOut }, "0.6")
    .to(mascotDeliversArmR, 0.6, { rotation: "-3deg", ease: Sine.easeOut }, "0")
    .to(mascotDeliversArmR, 0.6, { rotation: "0deg", ease: Sine.easeOut }, "0.6")
    .to(mascotDeliversBox, 0.6, { y: -10, ease: Sine.easeOut }, "0")
    .to(mascotDeliversBox, 0.6, { rotation: "1deg", ease: Sine.easeOut }, "0")
    .to(mascotDeliversBox, 0.6, { y: 0, ease: Sine.easeOut }, "0.6")
    .to(mascotDeliversBox, 0.6, { rotation: "-2deg", ease: Sine.easeOut }, "0.6")
    .to(mascotDeliversBody, 0.6, { skewX: "1.5deg", ease: Power2.easeInOut }, "0")
    .to(mascotDeliversBody, 0.6, { skewX: "0deg", ease: Power2.easeInOut }, "0.6")
    .to(mascotDeliversHead, 0.6, { y: 2, ease: Power2.easeOut }, "0")
    .to(mascotDeliversHead, 0.6, { y: 0, ease: Power2.easeInOut }, "0.6");

  mascotDeliversMouthTL = new TimelineMax({ paused: true, repeat: -1, repeatDelay: 0 });
  mascotDeliversMouthTL
    .to(mascotDeliversMouth, 0.2, { morphSVG: { shape: mascotDeliversMouth2 } }, "0")
    .to(mascotDeliversDimple, 0.2, { x: 7, y: -4, scaleX: 0.75, scaleY: 0.75 }, "0")
    .to(mascotDeliversMouth, 0.2, { scaleX: 0.75, scaleY: 0.75 }, "0.2")
    .to(mascotDeliversDimple, 0.2, { x: 6, y: -3 }, "0.2")
    .to(mascotDeliversMouth, 0.2, { scaleX: 1, scaleY: 1 }, "0.4")
    .to(mascotDeliversDimple, 0.2, { x: 7, y: -4 }, "0.4")
    .to(mascotDeliversMouth, 0.1, { scaleX: 0.75, scaleY: 0.75 }, "0.6")
    .to(mascotDeliversDimple, 0.1, { x: 6, y: -3 }, "0.6")
    .to(mascotDeliversMouth, 0.1, { scaleX: 1, scaleY: 1 }, "0.7")
    .to(mascotDeliversDimple, 0.1, { x: 7, y: -4 }, "0.7")
    .to(mascotDeliversMouth, 0.2, { scaleX: 0.75, scaleY: 0.75 }, "0.8")
    .to(mascotDeliversDimple, 0.2, { x: 6, y: -3 }, "0.8")
    .to(mascotDeliversMouth, 0.2, { scaleX: 1, scaleY: 1 }, "1")
    .to(mascotDeliversDimple, 0.2, { x: 7, y: -4 }, "1")
    .to(mascotDeliversMouth, 0.2, { scaleX: 0.75, scaleY: 0.75 }, "1.2")
    .to(mascotDeliversDimple, 0.2, { x: 6, y: -3 }, "1.2")
    .to(mascotDeliversMouth, 0.2, { scaleX: 1, scaleY: 1 }, "1.4")
    .to(mascotDeliversDimple, 0.2, { x: 7, y: -4 }, "1.4")
    .to(mascotDeliversMouth, 0.1, { scaleX: 0.75, scaleY: 0.75 }, "1.6")
    .to(mascotDeliversDimple, 0.1, { x: 6, y: -3 }, "1.6")
    .to(mascotDeliversMouth, 0.1, { scaleX: 1, scaleY: 1 }, "1.7")
    .to(mascotDeliversDimple, 0.1, { x: 7, y: -4 }, "1.7")
    .to(mascotDeliversMouth, 0.6, { morphSVG: { shape: mascotDeliversMouth } }, "1.8")
    .to(mascotDeliversDimple, 0.6, { x: 0, y: 0, scaleX: 1, scaleY: 1 }, "1.8")
    .to(mascotDeliversNote1, 1.2, { opacity: 1, scaleX: 1.5, scaleY: 1.5, x: 35, y: -70 }, "0")
    .to(mascotDeliversNote1, 0.6, { opacity: 0 }, "0.8")
    .to(mascotDeliversNote2, 1.2, { opacity: 1, scaleX: 1.5, scaleY: 1.5, x: 60, y: -40 }, "1.2")
    .to(mascotDeliversNote2, 0.6, { opacity: 0 }, "1.8");

  mascotDeliversTL.timeScale(1);
  mascotDeliversTL.play();
  mascotDeliversMouthTL.play();
}

function initMascotDelivers() {
  if (typeof TweenMax !== 'undefined') {
    initMascotDeliversAnimation();
  }
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initMascotDelivers);
} else {
  initMascotDelivers();
}
