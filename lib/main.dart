import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:charts_flutter/flutter.dart' as charts;

void main() {
  runApp(TrabalhoFinal());
}

class Deputado extends StatelessWidget {
  final int id;
  final String nome;
  final String email;
  final String imageUrl;
  final String siglaPartido;
  final String uf;

  Deputado(this.id, this.nome, this.email, this.imageUrl, this.siglaPartido,
      this.uf);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          CircleAvatar(radius: 20, backgroundImage: NetworkImage(imageUrl)),
      title: Text(nome),
      subtitle: Text(email),
      trailing: Icon(Icons.keyboard_arrow_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DetalhesParlamentar(id, this)),
        );
      },
    );
  }
}

class TrabalhoFinal extends StatefulWidget {
  @override
  _TrabalhoFinal createState() {
    return _TrabalhoFinal();
  }
}

class _TrabalhoFinal extends State<TrabalhoFinal> {
  List<Deputado> deputados = [];

  Future<List<Deputado>> listaDeputados() async {
    deputados.clear();

    final response = await http.get(
        'https://dadosabertos.camara.leg.br/api/v2/deputados?ordem=ASC&ordenarPor=nome');
    var jsondata = json.decode(response.body);

    for (var i = 0; i < jsondata['dados'].length; i++) {
      Deputado deputado = new Deputado(
          jsondata['dados'][i]['id'],
          jsondata['dados'][i]['nome'],
          jsondata['dados'][i]['email'],
          jsondata['dados'][i]['urlFoto'],
          jsondata['dados'][i]['siglaPartido'],
          jsondata['dados'][i]['siglaUf']);

      deputados.add(deputado);
    }

    return deputados;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Trabalho final Otativa II',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
            appBar: AppBar(
              title: Text("Deputado atualmente em exercício"),
            ),
            body: FutureBuilder<List<Deputado>>(
              initialData: deputados,
              future: listaDeputados(),
              builder: (context, snapshot) {
                final List<Deputado> dpts = snapshot.data;
                return ListView.builder(
                  itemBuilder: (context, index) {
                    return dpts[index];
                  },
                  itemCount: dpts.length,
                );
              },
            )));
  }
}

class Dispesa extends StatelessWidget {
  final int ano;
  final int mes;
  final String tipoDespesa;
  final String tipoDocumento;
  final DateTime dataDocumento;
  final String docLink;
  final String fornecedor;
  final double valorLiquido;

  Dispesa(this.ano, this.mes, this.tipoDespesa, this.tipoDocumento,
      this.dataDocumento, this.docLink, this.fornecedor, this.valorLiquido);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        child: Center(
            child: Text(valorLiquido.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white))),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          border: Border(),
          borderRadius: BorderRadius.all(
            Radius.circular(200),
          ),
          color: Colors.green,
        ),
      ),
      title: Text(tipoDespesa),
      subtitle: Text(
          "Em: " + dataDocumento.toString() + ', Fornecido por: ' + fornecedor),
      trailing: Icon(Icons.keyboard_arrow_right),
      onTap: () {
        /*
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetalhesParlamentar()),
        );
        */
      },
    );
  }
}

class DetalhesParlamentar extends StatefulWidget {
  final deputadoId;
  final Deputado deputado;

  DetalhesParlamentar(this.deputadoId, this.deputado);

  @override
  _DetalhesParlamentar createState() {
    return _DetalhesParlamentar(deputadoId, deputado);
  }
}

class XYDispesas {
  final double mes;
  final double valor;

  XYDispesas(this.mes, this.valor);
}

class _DetalhesParlamentar extends State<DetalhesParlamentar> {
  List<Dispesa> dispesas = [];
  double gastoTotal = 0.0;
  List<double> gastoPorMes = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  final deputadoId;
  final Deputado deputado;

  _DetalhesParlamentar(this.deputadoId, this.deputado);

  int ano = 2020;

  Future<List<Dispesa>> listaDispesas() async {
    dispesas.clear();

    var responseSize;
    var page = 1;

    do {
      var response = await http.get(
          'https://dadosabertos.camara.leg.br/api/v2/deputados/' +
              deputadoId.toString() +
              '/despesas?ano=' +
              ano.toString() +
              '&ordem=desc&ordenarPor=mes&itens=100&pagina=' +
              page.toString());
      page++;

      var jsondata = json.decode(response.body);
      responseSize = jsondata['dados'].length;

      for (var i = 0; i < jsondata['dados'].length; i++) {
        Dispesa dispesa = new Dispesa(
            int.tryParse(jsondata['dados'][i]['ano'].toString()),
            int.tryParse(jsondata['dados'][i]['mes'].toString()),
            jsondata['dados'][i]['tipoDespesa'].toString(),
            jsondata['dados'][i]['tipoDocumento'].toString(),
            DateTime.tryParse(jsondata['dados'][i]['dataDocumento'].toString()),
            jsondata['dados'][i]['urlDocumento'].toString(),
            jsondata['dados'][i]['nomeFornecedor'].toString(),
            double.tryParse(jsondata['dados'][i]['valorLiquido'].toString())
                .abs());
        dispesas.add(dispesa);
      }
    } while (responseSize > 0);

    return dispesas;
  }

  Widget buildBriefInfo() {
    gastoTotal = 0.0;
    List<XYDispesas> dispesasChartData = [];
    for (var i = 0; i < 12; i++) gastoPorMes[i] = 0;
    for (var i = 0; i < dispesas.length; i++) {
      gastoTotal += dispesas[i].valorLiquido;
      gastoPorMes[dispesas[i].mes - 1] += dispesas[i].valorLiquido;
      dispesasChartData.add(new XYDispesas(dispesas[i].mes.toDouble() - 1,
          gastoPorMes[dispesas[i].mes.toInt() - 1]));
    }

    var mes = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro'
    ];

    List<charts.Series<XYDispesas, String>> chartSeries = [
      new charts.Series<XYDispesas, String>(
        id: 'Dispesas',
        domainFn: (XYDispesas dispesas, _) => mes[dispesas.mes.toInt()],
        measureFn: (XYDispesas dispesas, _) => dispesas.valor,
        data: dispesasChartData,
        labelAccessorFn: (XYDispesas row, _) =>
            'Mês ' +
            row.mes.toInt().toString() +
            ' = ' +
            row.valor.toStringAsFixed(2),
      )
    ];

    return Container(
      height: 460,
      child: ListView(
        children: [
          Container(
            padding: new EdgeInsets.fromLTRB(0, 30, 0, 0),
            height: 180,
            child: Column(
              children: [
                Center(
                  child: Container(
                      padding: new EdgeInsets.fromLTRB(0, 0, 0, 10),
                      child: Text(
                        deputado.nome,
                        style: TextStyle(
                          fontSize: 32.0,
                        ),
                      )),
                ),
                Center(
                  child: Text(
                    'Gasto total no ano de ' + ano.toString(),
                    style: TextStyle(
                      fontSize: 22.0,
                    ),
                  ),
                ),
                Center(
                  child: Container(
                      padding: new EdgeInsets.all(10),
                      child: Text(
                        'R\$ ' + gastoTotal.toStringAsFixed(2),
                        style: TextStyle(fontSize: 32),
                      )),
                ),
              ],
            ),
          ),
          Container(
            padding: new EdgeInsets.fromLTRB(30, 0, 30, 0),
            height: 210,
            child: new PieOutsideLabelChart(
              chartSeries,
              animate: true,
            ),
          ),
          Container(
            height: 70,
            child: Center(
                child: Text('Detalhamento de gastos',
                    style: TextStyle(
                      fontSize: 22.0,
                    ))),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Dispesas Deputado"),
        ),
        body: Center(
            child: FutureBuilder<List<Dispesa>>(
          initialData: dispesas,
          future: listaDispesas(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              final List<Dispesa> dpts = snapshot.data;
              return ListView.builder(
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return buildBriefInfo();
                  } else {
                    return dpts[index - 1];
                  }
                },
                itemCount: dpts.length + 1,
              );
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return Text("Carregando...");
            }

            return null;
          },
        )));
  }
}

// --------------------------------------------

class PieOutsideLabelChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  PieOutsideLabelChart(this.seriesList, {this.animate});

  @override
  Widget build(BuildContext context) {
    return new charts.BarChart(
      seriesList,
      animate: animate,
      vertical: false,
      animationDuration: Duration(seconds: 1),
    );
  }
}
