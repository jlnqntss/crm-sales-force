({
  /**
   * Redirige a una URL cualquiera
   *
   * @author jmartinezpisson
   * @param {String} url URL de redirección
   * @param {Boolean} isRedirect Reemplaza la URL actual en el historial del navegador
   * @return {Promise}
   */
  redirectTo: function (url, isRedirect) {
    let redirectEvent = $A.get("e.force:navigateToURL");

    if (url) {
      if (window.sforce && window.sforce.one) {
        sforce.one.navigateToURL(url, isRedirect);
      } else if (redirectEvent) {
        redirectEvent
          .setParams({
            url: url,
            isRedirect: isRedirect
          })
          .fire();
      }
    }

    return Promise.resolve();
  }
});
