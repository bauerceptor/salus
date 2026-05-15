document.addEventListener("DOMContentLoaded", function() {
  const container = document.getElementById("chat-container");
  if (!container) return;

  const lineWidth = 500;
  const profileImgWidth = 60;
  const textWidth = lineWidth - 20 - profileImgWidth - 10;
  const chats = [];
  const maxTexts = 4;
  const amountOfColors = 18;

  function createElement(opts = {}) {
    const ele = document.createElement("div");
    if ("class" in opts) {
      if (!Array.isArray(opts.class)) {
        opts.class = [opts.class];
      }
      ele.classList.add(...opts.class);
    }
    return ele;
  }

  function addChat() {
    const chat = new Chat();
    chats.push(chat);
    setTimeout(() => chat.loop(), 200);
    return chat;
  }

  class Chat {
    constructor() {
      this.ele = createElement({ class: "chat" });
      this.lines = [];
      this.anim = null;
      container.appendChild(this.ele);
    }

    addLine() {
      const l = new Line();
      this.lines.push(l);
      this.ele.appendChild(l.ele.lineContainer);
      return l;
    }

    removeOldest() {
      const maxCount = Math.ceil(window.innerHeight / 1080 * 12);
      if (this.lines.length > maxCount) {
        const oldest = this.lines.splice(0, this.lines.length - maxCount);
        oldest.forEach((n) => this.ele.removeChild(n.ele.lineContainer));
      }
    }

    loop() {
      if (this.anim) {
        this.stopLoop();
      }
      this.addLine();
      this.removeOldest();
      this.anim = setTimeout(() => this.loop(), Math.random() * 1300 + 180);
    }

    stopLoop() {
      clearTimeout(this.anim);
      this.anim = null;
    }
  }

  class Line {
    constructor() {
      this.pickColor();
      this.pickName();
      this.pickText();
      this.pickHasImg();
      this.pickHasRichBody();
      this.setupElements();
      this.animateIn();
    }

    pickColor() {
      this.hue = Math.floor(Math.random() * amountOfColors) * (360 / amountOfColors);
      this.color = `hsl(${this.hue}, 90%, 50%)`;
      this.profileImgColor = `hsl(${this.hue}, 40%, 55%)`;
      return this.hue;
    }

    pickName() {
      this.name = Math.max(0.3, Math.random());
    }

    pickText() {
      const lengthChoice = Math.random();
      let lengthWeight = 1;
      if (lengthChoice < 0.5) {
        lengthWeight = 0.6;
      } else if (lengthChoice < 0.9) {
        lengthWeight = 0.8;
      }
      this.length = Math.max(0.02, lengthChoice * lengthWeight);
      this.textCount = Math.floor(this.length * maxTexts) || 1;
    }

    pickHasImg() {
      this.hasImg = Math.random() > 0.9;
    }

    pickHasRichBody() {
      this.hasRichBody = !this.hasImg && Math.random() > 0.85;
    }

    setupElements() {
      const ele = this.createElement();
      this.ele = ele;
      ele.name.style.width = this.name * (textWidth / 2) + "px";
      ele.texts.forEach((n, i, arr) => {
        let w = textWidth;
        if (i === arr.length - 1) {
          w = Math.max(0.2, this.textCount - i) * textWidth;
        }
        n.style.width = w + "px";
      });
      ele.name.style.backgroundColor = this.color;
      ele.profileImg.style.backgroundColor = this.profileImgColor;
    }

    animateIn() {
      let delay = 35;
      const ele = this.ele;
      setTimeout(() => {
        ele.lineContainer.style.opacity = 1;
        ele.lineContainer.style.maxHeight = "200px";
        ele.lineContainer.style.transform = "translateX(0px) scale(1)";
      }, delay);

      const otherEleList = [ele.profileImg, ele.name, ...ele.texts];

      if ("img" in ele) {
        otherEleList.push(ele.img);
      } else if ("richBody" in ele) {
        otherEleList.push(ele.richBody);
      }

      delay += 40;

      otherEleList.forEach((e, i) => {
        setTimeout(() => {
          e.style.opacity = 1;
          e.style.transform = "translateY(0px)";
        }, delay + i * 50);
      });

      ele.texts.forEach((n, i) =>
        setTimeout(() => (n.style.opacity = 1), 70 * (i + 3) + delay)
      );
    }

    createElement() {
      const lineContainer = createElement({ class: "line-container" });
      const line = createElement({ class: "line" });
      const profileImg = createElement({ class: "profile-img" });
      const body = createElement({ class: "body" });
      const name = createElement({ class: "name" });
      const texts = [];
      const img = createElement({ class: "img" });
      const richBody = createElement({ class: "rich-body" });

      body.appendChild(name);
      for (let i = 0; i < this.textCount; i++) {
        const text = createElement({ class: "text" });
        texts.push(text);
        body.appendChild(text);
      }
      line.appendChild(profileImg);
      line.appendChild(body);
      lineContainer.appendChild(line);

      const out = { lineContainer, line, profileImg, body, name, texts };
      if (this.hasImg) {
        out.img = img;
        body.appendChild(img);
      }
      if (this.hasRichBody) {
        out.richBody = richBody;
        body.appendChild(richBody);
      }
      return out;
    }
  }

  addChat();
});
