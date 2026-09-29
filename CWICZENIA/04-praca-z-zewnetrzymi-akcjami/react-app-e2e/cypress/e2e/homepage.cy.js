describe('React application', () => {
  it('renders the React screen and loads its logo', () => {
    cy.visit('/');

    // These elements are rendered by React, so an empty HTML shell will fail.
    cy.get('#root .App').should('be.visible');
    cy.contains('code', 'src/App.tsx').should('be.visible');
    cy.contains('a', 'Learn React')
      .should('be.visible')
      .and('have.attr', 'href', 'https://reactjs.org');
    cy.get('img[alt="logo"]').should('be.visible').and(($image) => {
      expect($image[0].naturalWidth, 'loaded logo width').to.be.greaterThan(0);
    });

    cy.screenshot('react-homepage');
  });
});
