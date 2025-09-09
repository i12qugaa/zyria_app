import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_app/controllers/activos_controller.dart';
import 'package:finanzas_app/controllers/deudas_controller.dart';

void main() {
  final activosController = ActivosController();
  final deudasController = DeudasController();

  group('Validaciones de formularios de activos', () {
    test('Nombre vacío devuelve error', () {
      expect(activosController.validarNombre(''), 'Por favor, ingresa un nombre.');
    });

    test('Nombre válido devuelve null', () {
      expect(activosController.validarNombre('Piso en Madrid'), null);
    });

    test('Símbolo vacío devuelve error', () {
      expect(activosController.validarSimbolo(''), 'Por favor, ingresa un símbolo.');
    });

    test('Valor numérico válido devuelve null', () {
      expect(activosController.validarValor('1234.56'), null);
    });

    test('Valor no numérico devuelve error', () {
      expect(activosController.validarValor('abc'), 'Por favor, ingresa un valor válido.');
    });

    test('Ingreso mensual vacío devuelve error', () {
      expect(activosController.validarIngresoMensual(''), 'Por favor, introduzca el ingreso mensual.');
    });

    test('Ingreso mensual válido devuelve null', () {
      expect(activosController.validarIngresoMensual('1000,50'), null);
    });

    test('Cantidad menor o igual a 0 devuelve error', () {
      expect(activosController.validarCantidad('0'), 'Cantidad inválida (debe ser > 0)');
    });

    test('Cantidad válida devuelve null', () {
      expect(activosController.validarCantidad('1.5'), null);
    });

    test('Comisión vacía (opcional) devuelve null', () {
      expect(activosController.validarComision(''), null);
    });

    test('Comisión negativa devuelve error', () {
      expect(activosController.validarComision('-3'), 'Comisión inválida');
    });
  });

  group('Validaciones de formularios de deudas', () {
    test('Entidad vacía devuelve error', () {
      expect(deudasController.validarEntidad(''), 'Por favor, ingresa una entidad.');
    });

    test('Valor no numérico devuelve error', () {
      expect(deudasController.validarValor('abc'), 'Por favor, ingresa un valor válido.');
    });

    test('Interés negativo devuelve error', () {
      expect(deudasController.validarInteres('-1'), 'Interés inválido.');
    });

    test('Interés válido devuelve null', () {
      expect(deudasController.validarInteres('3.5'), null);
    });

    test('Plazo vacío devuelve error', () {
      expect(deudasController.validarPlazo(''), 'Por favor, ingresa el plazo.');
    });

    test('Plazo inválido devuelve error', () {
      expect(deudasController.validarPlazo('0'), 'Plazo inválido.');
    });

    test('Plazo válido devuelve null', () {
      expect(deudasController.validarPlazo('12'), null);
    });

    test('Fecha nula devuelve error', () {
      expect(deudasController.validarFecha(null), 'Selecciona una fecha de inicio.');
    });

    test('Fecha válida devuelve null', () {
      expect(deudasController.validarFecha(DateTime.now()), null);
    });

    test('Cantidad vacía devuelve error', () {
      expect(deudasController.validarCantidad(''), 'Por favor, ingresa un valor.');
    });

    test('Cantidad inválida devuelve error', () {
      expect(deudasController.validarCantidad('0'), 'Cantidad inválida (debe ser > 0)');
    });

    test('Cantidad válida devuelve null', () {
      expect(deudasController.validarCantidad('10.5'), null);
    });
  });
}
