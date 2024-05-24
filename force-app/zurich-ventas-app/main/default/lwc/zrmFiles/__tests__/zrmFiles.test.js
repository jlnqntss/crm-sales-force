import { createElement } from 'lwc';
import ZRMFiles from 'c/zRMFiles';

describe('c-zrm-files', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('TODO: test case generated by CLI command, please fill in test logic', () => {
        // Arrange
        const element = createElement('c-zrm-files', {
            is: ZRMFiles
        });

        // Act
        document.body.appendChild(element);

        // Assert
        expect(1).toBe(1);
    });
});