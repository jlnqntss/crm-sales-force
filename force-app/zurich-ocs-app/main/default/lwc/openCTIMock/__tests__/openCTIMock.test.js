import { createElement } from "lwc";
import OpenCTIMock from "c/openCTIMock";

describe("c-open-c-t-i-mock", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  test("Cuando se pulsa la tecla 1, se rellena la lista de interacciones", () => {
    const element = createElement("c-open-c-t-i-mock", {
      is: OpenCTIMock
    });
    document.body.appendChild(element);

    element.doScreenPop = () => {
      return Promise.resolve();
    };

    element.doCreateCall = () => {
      return Promise.resolve();
    };

    element.shadowRoot.querySelector("div div").firstChild.dispatchEvent(
      new KeyboardEvent("keyup", {
        code: "Digit1",
        bubbles: true
      })
    );

    return Promise.resolve().then(() => {
      expect(
        element.shadowRoot.querySelectorAll("ul li").length
      ).toBeGreaterThan(0);
    });
  });
});
