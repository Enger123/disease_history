import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum FType { text, multiline, date }

class Field {
  final String key, label;
  final FType type;
  const Field(this.key, this.label, [this.type = FType.text]);
}

/// Опис розділу. Перше поле = заголовок запису, поле 'date' = дата.
/// За цим описом генеруються таблиці БД, списки, форми і пошук.
class Section {
  final String table, title;
  final IconData icon;
  final List<Field> fields;
  const Section(this.table, this.title, this.icon, this.fields);
}

const sections = [
  Section('illnesses', 'Хвороби', Icons.sick, [
    Field('title', 'Що боліло / діагноз'),
    Field('date', 'Дата', FType.date),
    Field('description', 'Опис, симптоми', FType.multiline),
  ]),
  Section('visits', 'Візити', Icons.local_hospital, [
    Field('doctor', 'Лікар (ПІБ)'),
    Field('specialty', 'Спеціальність'),
    Field('date', 'Дата візиту', FType.date),
    Field('notes', 'Висновок, рекомендації', FType.multiline),
  ]),
  Section('medications', 'Ліки', Icons.medication, [
    Field('name', 'Назва препарату'),
    Field('dosage', 'Дозування'),
    Field('date', 'Початок прийому', FType.date),
    Field('notes', 'Примітки (хто призначив, курс)', FType.multiline),
  ]),
];

final _ui = DateFormat('dd.MM.yyyy');
String toUi(String? iso) => (iso == null || iso.isEmpty) ? '' : _ui.format(DateTime.parse(iso));
String toIso(String ui) => DateFormat('yyyy-MM-dd').format(_ui.parse(ui));
