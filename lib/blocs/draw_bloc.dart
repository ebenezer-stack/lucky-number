import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../database/database_helper.dart';
import '../models/draw_model.dart';

// Events
abstract class DrawEvent extends Equatable {
  const DrawEvent();
  @override
  List<Object?> get props => [];
}

class InitializeDraw extends DrawEvent {}

class PerformRandomDraw extends DrawEvent {
  final int min;
  final int max;
  final int winnersCount;
  final bool allowDuplicates;
  final List<int>? candidatePool;

  const PerformRandomDraw({
    required this.min,
    required this.max,
    required this.winnersCount,
    required this.allowDuplicates,
    this.candidatePool,
  });

  @override
  List<Object?> get props => [min, max, winnersCount, allowDuplicates, candidatePool];
}

class PerformForcedDraw extends DrawEvent {
  final List<int> winners;
  final int min;
  final int max;

  const PerformForcedDraw({
    required this.winners,
    required this.min,
    required this.max,
  });

  @override
  List<Object?> get props => [winners, min, max];
}

class LoadDrawHistory extends DrawEvent {
  final int offset;
  final int limit;

  const LoadDrawHistory({this.offset = 0, this.limit = 20});

  @override
  List<Object?> get props => [offset, limit];
}

class DeleteDraw extends DrawEvent {
  final int id;
  const DeleteDraw(this.id);
  @override
  List<Object?> get props => [id];
}

class ClearAllDraws extends DrawEvent {}

class AnimationTick extends DrawEvent {
  final List<int> currentNumbers;
  final List<int> finalNumbers;
  const AnimationTick(this.currentNumbers, this.finalNumbers);
  @override
  List<Object?> get props => [currentNumbers, finalNumbers];
}

class AnimationComplete extends DrawEvent {
  final List<int> finalNumbers;
  final int min;
  final int max;
  final bool allowDuplicates;
  final String mode;

  const AnimationComplete({
    required this.finalNumbers,
    required this.min,
    required this.max,
    required this.allowDuplicates,
    required this.mode,
  });

  @override
  List<Object?> get props => [finalNumbers, min, max, allowDuplicates, mode];
}

enum DrawStatus { idle, starting, animating, finishing, completed, error }

// Single State Class
class DrawState extends Equatable {
  final List<Draw> history;
  final bool isLoading;
  final String? error;
  final List<int>? animatingNumbers;
  final List<int>? finalNumbers;
  final int tickCount;
  final Draw? lastDraw;
  final bool hasMore;
  final DrawStatus status;

  const DrawState({
    this.history = const [],
    this.isLoading = false,
    this.error,
    this.animatingNumbers,
    this.finalNumbers,
    this.tickCount = 0,
    this.lastDraw,
    this.hasMore = false,
    this.status = DrawStatus.idle,
  });

  DrawState copyWith({
    List<Draw>? history,
    bool? isLoading,
    String? error,
    List<int>? animatingNumbers,
    List<int>? finalNumbers,
    int? tickCount,
    Draw? lastDraw,
    bool? hasMore,
    DrawStatus? status,
  }) {
    return DrawState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      animatingNumbers: animatingNumbers ?? this.animatingNumbers,
      finalNumbers: finalNumbers ?? this.finalNumbers,
      tickCount: tickCount ?? this.tickCount,
      lastDraw: lastDraw ?? this.lastDraw,
      hasMore: hasMore ?? this.hasMore,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [history, isLoading, error, animatingNumbers, finalNumbers, tickCount, lastDraw, hasMore, status];
}

// BLoC
class DrawBloc extends Bloc<DrawEvent, DrawState> {
  final DatabaseHelper _database;
  Timer? _animationTimer;
  List<int>? _finalNumbers;
  int _tickCount = 0;
  static const int _totalTicks = 20;

  DrawBloc({DatabaseHelper? database})
      : _database = database ?? DatabaseHelper.instance,
        super(const DrawState()) {
    on<InitializeDraw>(_onInitializeDraw);
    on<PerformRandomDraw>(_onPerformRandomDraw);
    on<PerformForcedDraw>(_onPerformForcedDraw);
    on<LoadDrawHistory>(_onLoadDrawHistory);
    on<DeleteDraw>(_onDeleteDraw);
    on<ClearAllDraws>(_onClearAllDraws);
    on<AnimationTick>(_onAnimationTick);
    on<AnimationComplete>(_onAnimationComplete);
  }

  @override
  Future<void> close() {
    _animationTimer?.cancel();
    return super.close();
  }

  Future<void> _onInitializeDraw(
    InitializeDraw event,
    Emitter<DrawState> emit,
  ) async {
    add(const LoadDrawHistory());
  }

  Future<void> _onPerformRandomDraw(
    PerformRandomDraw event,
    Emitter<DrawState> emit,
  ) async {
    final random = Random();
    final numbers = <int>[];
    
    if (event.candidatePool != null && event.candidatePool!.isNotEmpty) {
      final pool = event.candidatePool!;
      if (!event.allowDuplicates && event.winnersCount > pool.length) {
        emit(state.copyWith(error: 'Le nombre de gagnants dépasse la liste disponible sans doublons'));
        return;
      }

      while (numbers.length < event.winnersCount) {
        final number = pool[random.nextInt(pool.length)];
        if (event.allowDuplicates || !numbers.contains(number)) {
          numbers.add(number);
        }
      }
    } else {
      final range = event.max - event.min + 1;
      if (!event.allowDuplicates && event.winnersCount > range) {
        emit(state.copyWith(error: 'Le nombre de gagnants dépasse la plage disponible sans doublons'));
        return;
      }

      while (numbers.length < event.winnersCount) {
        final number = event.min + random.nextInt(range);
        if (event.allowDuplicates || !numbers.contains(number)) {
          numbers.add(number);
        }
      }
    }
    
    numbers.sort();
    _finalNumbers = numbers;
    _tickCount = 0;

    _startAnimation(event.min, event.max, event.winnersCount, 'random', emit, candidatePool: event.candidatePool);
  }

  Future<void> _onPerformForcedDraw(
    PerformForcedDraw event,
    Emitter<DrawState> emit,
  ) async {
    _finalNumbers = List<int>.from(event.winners)..sort();
    _tickCount = 0;
    _startAnimation(event.min, event.max, event.winners.length, 'manual', emit);
  }

  void _startAnimation(int min, int max, int count, String mode, Emitter<DrawState> emit, {List<int>? candidatePool}) {
    final random = Random();
    
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        _tickCount++;
        
        final displayedNumbers = List<int>.generate(
          count,
          (_) {
            if (candidatePool != null && candidatePool.isNotEmpty) {
              return candidatePool[random.nextInt(candidatePool.length)];
            }
            return min + random.nextInt(max - min + 1);
          },
        );
        
        if (_tickCount >= _totalTicks) {
          timer.cancel();
          add(AnimationTick(_finalNumbers!, _finalNumbers!));
          add(AnimationComplete(
            finalNumbers: _finalNumbers!,
            min: min,
            max: max,
            allowDuplicates: false,
            mode: mode,
          ));
        } else {
          add(AnimationTick(displayedNumbers, _finalNumbers!));
        }
      },
    );

    emit(state.copyWith(status: DrawStatus.starting));
    
    final initialNumbers = List<int>.generate(
      count,
      (_) {
        if (candidatePool != null && candidatePool.isNotEmpty) {
          return candidatePool[random.nextInt(candidatePool.length)];
        }
        return min + random.nextInt(max - min + 1);
      },
    );
    emit(state.copyWith(
      status: DrawStatus.animating,
      animatingNumbers: initialNumbers,
      finalNumbers: _finalNumbers!,
      tickCount: 0,
      lastDraw: null,
    ));
  }

  void _onAnimationTick(
    AnimationTick event,
    Emitter<DrawState> emit,
  ) {
    emit(state.copyWith(
      animatingNumbers: event.currentNumbers,
      finalNumbers: event.finalNumbers,
      tickCount: _tickCount,
    ));
  }

  Future<void> _onAnimationComplete(
    AnimationComplete event,
    Emitter<DrawState> emit,
  ) async {
    // 1. Victory pause
    emit(state.copyWith(
      status: DrawStatus.finishing,
      tickCount: _totalTicks,
      animatingNumbers: event.finalNumbers,
    ));

    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      final draw = Draw(
        winningNumbers: event.finalNumbers,
        mode: event.mode,
        winnersCount: event.finalNumbers.length,
        date: DateTime.now(),
        minRange: event.min,
        maxRange: event.max,
        allowDuplicates: event.allowDuplicates,
      );

      await _database.insertDraw(draw);
      final history = await _database.getAllDraws();
      
      emit(state.copyWith(
        status: DrawStatus.completed,
        lastDraw: draw,
        history: history,
        animatingNumbers: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DrawStatus.error,
        error: 'Erreur lors du tirage: $e',
        animatingNumbers: null,
      ));
    }
  }

  Future<void> _onLoadDrawHistory(
    LoadDrawHistory event,
    Emitter<DrawState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final draws = await _database.getDrawsPaginated(event.offset, event.limit);
      final totalCount = await _database.getDrawsCount();
      
      emit(state.copyWith(
        isLoading: false,
        history: event.offset == 0 ? draws : [...state.history, ...draws],
        hasMore: (event.offset + draws.length) < totalCount,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Erreur lors du chargement de l\'historique: $e'));
    }
  }

  Future<void> _onDeleteDraw(
    DeleteDraw event,
    Emitter<DrawState> emit,
  ) async {
    try {
      await _database.deleteDraw(event.id);
      add(const LoadDrawHistory());
    } catch (e) {
      emit(state.copyWith(error: 'Erreur lors de la suppression: $e'));
    }
  }

  Future<void> _onClearAllDraws(
    ClearAllDraws event,
    Emitter<DrawState> emit,
  ) async {
    try {
      await _database.deleteAllDraws();
      add(const LoadDrawHistory());
    } catch (e) {
      emit(state.copyWith(error: 'Erreur lors de la suppression: $e'));
    }
  }
}
