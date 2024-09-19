const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");
module.exports = {
  ...jestConfig,
  moduleNameMapper: {
    "^lightning/modal$":
      "<rootDir>/force-app/zurich-base/main/default/test/jest-mocks/lightning/modal",
    "^lightning/modalHeader$":
      "<rootDir>/force-app/zurich-base/main/default/test/jest-mocks/lightning/modalHeader",
    "^lightning/modalBody$":
      "<rootDir>/force-app/zurich-base/main/default/test/jest-mocks/lightning/modalBody",
    "^lightning/modalFooter$":
      "<rootDir>/force-app/zurich-base/main/default/test/jest-mocks/lightning/modalFooter"
  }
};
