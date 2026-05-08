import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../database/database_helper.dart';
import '../models/statistics_model.dart';

abstract class StatisticsEvent extends Equatable {
  const StatisticsEvent();
  @override
  List<Object?> get props => [];
}

class LoadStatistics extends StatisticsEvent {}
class RefreshStatistics extends StatisticsEvent {}

abstract class StatisticsState extends Equatable {
  const StatisticsState();
  @override
  List<Object?> get props => [];
}

class StatisticsInitial extends StatisticsState {}
class StatisticsLoading extends StatisticsState {}
class StatisticsLoaded extends StatisticsState {
  final List<NumberStatistics> statistics;
  final int totalDraws;
  final int uniqueNumbers;

  const StatisticsLoaded({
    required this.statistics,
    required this.totalDraws,
    required this.uniqueNumbers,
  });

  @override
  List<Object?> get props => [statistics, totalDraws, uniqueNumbers];

  NumberStatistics? get mostFrequent => statistics.isNotEmpty ? statistics.first : null;
  NumberStatistics? get leastFrequent => statistics.isNotEmpty ? statistics.last : null;
  double get averageFrequency => statistics.isNotEmpty 
      ? statistics.map((s) => s.frequency).reduce((a, b) => a + b) / statistics.length 
      : 0;
}
class StatisticsEmpty extends StatisticsState {}
class StatisticsError extends StatisticsState {
  final String message;
  const StatisticsError(this.message);
  @override
  List<Object?> get props => [message];
}

class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final DatabaseHelper _database;

  StatisticsBloc({DatabaseHelper? database})
      : _database = database ?? DatabaseHelper.instance,
        super(StatisticsInitial()) {
    on<LoadStatistics>(_onLoadStatistics);
    on<RefreshStatistics>(_onRefreshStatistics);
  }

  Future<void> _onLoadStatistics(LoadStatistics event, Emitter<StatisticsState> emit) async {
    emit(StatisticsLoading());
    try {
      final statsData = await _database.getStatistics();
      final totalDraws = await _database.getDrawsCount();

      if (statsData.isEmpty) {
        emit(StatisticsEmpty());
        return;
      }

      final statistics = statsData.map((data) => NumberStatistics.fromMap(data)).toList();

      emit(StatisticsLoaded(
        statistics: statistics,
        totalDraws: totalDraws,
        uniqueNumbers: statistics.length,
      ));
    } catch (e) {
      emit(StatisticsError('Erreur lors du chargement des statistiques: $e'));
    }
  }

  Future<void> _onRefreshStatistics(RefreshStatistics event, Emitter<StatisticsState> emit) async {
    add(LoadStatistics());
  }
}
