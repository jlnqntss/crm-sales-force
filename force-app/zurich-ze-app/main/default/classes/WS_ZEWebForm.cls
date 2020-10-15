/**
 * Clase que implementa el Web Service REST a consumir por el formulario web de Zurich Empresas
 *
 * @author rlopez
 * @date 14/10/2020
 */
@RestResource(urlMapping='/v1/ze/webform/*')
global with sharing class WS_ZEWebForm {
  /**
   * Metodo Post que recibe la información del formulario web y procesa dicha información
   * en función del paso en el que se encuentre
   * @author rlopez
   * @date 14/10/2020
   */
  @HttpPost
  global static String doPost() {
    return 'OK';
  }
}
