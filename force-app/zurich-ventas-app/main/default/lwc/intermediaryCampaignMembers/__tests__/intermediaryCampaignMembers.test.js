import { createElement } from 'lwc';
import IntermediaryCampaignMembers from 'c/intermediaryCampaignMembers';

describe('c-intermediary-campaign-members', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('TODO: test case generated by CLI command, please fill in test logic', () => {
        // Arrange
        const element = createElement('c-intermediary-campaign-members', {
            is: IntermediaryCampaignMembers
        });

        // Act
        document.body.appendChild(element);

        // Assert
        expect(1).toBe(1);
    });
});