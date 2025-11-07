// lib/screens/map_screen.dart (Force-Directed Layout ile Sürekli Hareket)

import 'package:flutter/material.dart';
import 'package:innermap/models/concept_edge.dart';
import 'package:innermap/models/concept_node.dart';
import 'dart:math';

class MapScreen extends StatefulWidget {
  final List<ConceptNode> nodes;
  final List<ConceptEdge> edges;

  const MapScreen({
    super.key,
    required this.nodes,
    required this.edges,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final Map<String, Offset> _nodePositions = {};
  final Map<String, Offset> _nodeVelocities = {};
  final Set<String> _pinnedNodes = {}; // Sabitlenen düğümler
  final double _nodeRadius = 40.0;
  
  late AnimationController _animationController;
  String? _draggedNodeId;
  
  // Fizik parametreleri (Daha sakin hareket için optimize edildi)
  final double _repulsionStrength = 1000.0;  // 5000 → 1000 (daha az itme)
  final double _attractionStrength = 0.005;  // 0.01 → 0.005 (daha az çekim)
  final double _damping = 0.75;              // 0.85 → 0.75 (daha fazla sürtünme)
  final double _centerForce = 0.0005;        // 0.001 → 0.0005 (daha yumuşak merkeze çekim)
  
  // Canvas sınırları
  double _minX = 0, _maxX = 0, _minY = 0, _maxY = 0;
  final double _padding = 100.0;
  
  TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 32), // 16ms → 32ms (~30 FPS, daha yavaş)
    )..addListener(_updatePhysics);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNodePositions();
      _animationController.repeat();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _initializeNodePositions() {
    if (!mounted || widget.nodes.isEmpty) return;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double centerX = screenWidth / 2;
    final double centerY = screenHeight / 2;

    setState(() {
      // Rastgele başlangıç pozisyonları
      final Random random = Random();
      for (final node in widget.nodes) {
        _nodePositions[node.id] = Offset(
          centerX + (random.nextDouble() - 0.5) * 200,
          centerY + (random.nextDouble() - 0.5) * 200,
        );
        _nodeVelocities[node.id] = Offset.zero;
      }
      
      _updateBounds();
    });
  }

  void _updatePhysics() {
    if (_nodePositions.isEmpty || _draggedNodeId != null) return;

    setState(() {
      final Map<String, Offset> forces = {};
      
      // Tüm düğümler için kuvvet hesapla
      for (final node in widget.nodes) {
        forces[node.id] = Offset.zero;
      }

      // 1. İtme Kuvveti (Düğümler birbirini iter)
      for (int i = 0; i < widget.nodes.length; i++) {
        for (int j = i + 1; j < widget.nodes.length; j++) {
          final node1 = widget.nodes[i];
          final node2 = widget.nodes[j];
          
          final pos1 = _nodePositions[node1.id];
          final pos2 = _nodePositions[node2.id];
          
          if (pos1 == null || pos2 == null) continue;
          
          final delta = pos1 - pos2;
          final distance = max(delta.distance, 10.0); // Minimum mesafe 10
          
          // NaN kontrolü
          if (distance.isNaN || distance.isInfinite) continue;
          
          // Coulomb itme kuvveti
          final forceMagnitude = _repulsionStrength / (distance * distance);
          if (forceMagnitude.isNaN || forceMagnitude.isInfinite) continue;
          
          final force = delta / distance * forceMagnitude;
          
          if (!force.dx.isNaN && !force.dy.isNaN) {
            forces[node1.id] = forces[node1.id]! + force;
            forces[node2.id] = forces[node2.id]! - force;
          }
        }
      }

      // 2. Çekim Kuvveti (Bağlantılı düğümler birbirini çeker)
      for (final edge in widget.edges) {
        final source = _nodePositions[edge.sourceId];
        final target = _nodePositions[edge.targetId];
        
        if (source != null && target != null) {
          final delta = target - source;
          final distance = delta.distance;
          
          // NaN kontrolü
          if (distance.isNaN || distance.isInfinite) continue;
          
          // Hooke yay kuvveti
          final force = delta * _attractionStrength * distance;
          
          if (!force.dx.isNaN && !force.dy.isNaN) {
            forces[edge.sourceId] = forces[edge.sourceId]! + force;
            forces[edge.targetId] = forces[edge.targetId]! - force;
          }
        }
      }

      // 3. Merkez Çekim Kuvveti (Düğümleri merkeze doğru çeker)
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final center = Offset(screenWidth / 2, screenHeight / 2);
      
      for (final node in widget.nodes) {
        final pos = _nodePositions[node.id];
        if (pos == null) continue;
        
        final toCenter = center - pos;
        if (!toCenter.dx.isNaN && !toCenter.dy.isNaN) {
          forces[node.id] = forces[node.id]! + toCenter * _centerForce;
        }
      }

      // Kuvvetleri uygula ve pozisyonları güncelle
      for (final node in widget.nodes) {
        // Sürüklenen veya sabitlenen düğümleri atla
        if (node.id == _draggedNodeId || _pinnedNodes.contains(node.id)) continue;
        
        final force = forces[node.id];
        if (force == null) continue;
        
        // NaN kontrolü
        if (force.dx.isNaN || force.dy.isNaN) continue;
        
        // Hız güncelleme
        final currentVelocity = _nodeVelocities[node.id] ?? Offset.zero;
        final newVelocity = (currentVelocity + force) * _damping;
        
        // Hız limiti (aşırı hızlanmayı önle)
        final speed = newVelocity.distance;
        if (speed > 10.0) {  // 50.0 → 10.0 (daha yavaş maksimum hız)
          _nodeVelocities[node.id] = newVelocity / speed * 10.0;
        } else {
          _nodeVelocities[node.id] = newVelocity;
        }
        
        // Pozisyon güncelleme
        final currentPosition = _nodePositions[node.id];
        if (currentPosition == null) continue;
        
        final newPosition = currentPosition + _nodeVelocities[node.id]!;
        
        // Pozisyon kontrolü
        if (!newPosition.dx.isNaN && !newPosition.dy.isNaN) {
          _nodePositions[node.id] = newPosition;
        }
      }
      
      _updateBounds();
    });
  }

  void _updateBounds() {
    if (_nodePositions.isEmpty) return;
    
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    
    for (final pos in _nodePositions.values) {
      if (pos.dx.isNaN || pos.dy.isNaN) continue;
      
      minX = min(minX, pos.dx);
      maxX = max(maxX, pos.dx);
      minY = min(minY, pos.dy);
      maxY = max(maxY, pos.dy);
    }
    
    // Geçerli değerler yoksa varsayılan değerler kullan
    if (minX.isInfinite || maxX.isInfinite || minY.isInfinite || maxY.isInfinite) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      _minX = 0;
      _maxX = screenWidth;
      _minY = 0;
      _maxY = screenHeight;
    } else {
      _minX = minX - _padding;
      _maxX = maxX + _padding;
      _minY = minY - _padding;
      _maxY = maxY + _padding;
    }
  }

  void _handleNodeDragStart(String nodeId) {
    setState(() {
      _draggedNodeId = nodeId;
      _nodeVelocities[nodeId] = Offset.zero;
      _pinnedNodes.add(nodeId); // Düğümü sabitle
    });
  }

  void _handleNodeDrag(String nodeId, DragUpdateDetails details) {
    setState(() {
      final currentPosition = _nodePositions[nodeId]!;
      _nodePositions[nodeId] = currentPosition + details.delta / _transformController.value.getMaxScaleOnAxis();
      _nodeVelocities[nodeId] = Offset.zero;
    });
  }

  void _handleNodeDragEnd(String nodeId) {
    setState(() {
      _draggedNodeId = null;
      _nodeVelocities[nodeId] = Offset.zero;
      // Düğüm sabitlemeye devam eder, fizik uygulanmaz
    });
  }
  
  void _unpinNode(String nodeId) {
    setState(() {
      _pinnedNodes.remove(nodeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_nodePositions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kavram Haritası Yükleniyor')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final canvasWidth = max(_maxX - _minX, MediaQuery.of(context).size.width);
    final canvasHeight = max(_maxY - _minY, MediaQuery.of(context).size.height);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kavram Haritası'),
        actions: [
          IconButton(
            icon: const Icon(Icons.push_pin_outlined),
            tooltip: 'Tüm Sabitlemeleri Kaldır',
            onPressed: () {
              setState(() {
                _pinnedNodes.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yeniden Düzenle',
            onPressed: () {
              setState(() {
                _pinnedNodes.clear();
              });
              _initializeNodePositions();
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            tooltip: 'Sığdır',
            onPressed: () {
              _transformController.value = Matrix4.identity();
            },
          ),
        ],
      ),
      body: InteractiveViewer(
        transformationController: _transformController,
        boundaryMargin: const EdgeInsets.all(100),
        minScale: 0.1,
        maxScale: 4.0,
        constrained: false,
        child: SizedBox(
          width: canvasWidth,
          height: canvasHeight,
          child: Stack(
            children: [
              // Bağlantıları çiz
              CustomPaint(
                size: Size(canvasWidth, canvasHeight),
                painter: MindMapPainter(
                  nodes: widget.nodes,
                  edges: widget.edges,
                  nodePositions: _nodePositions,
                  nodeRadius: _nodeRadius,
                  offsetX: -_minX,
                  offsetY: -_minY,
                ),
              ),

              // Düğümleri çiz
              ...widget.nodes.map((node) {
                final position = _nodePositions[node.id];
                if (position == null) return const SizedBox.shrink();

                return Positioned(
                  left: position.dx - _nodeRadius - _minX,
                  top: position.dy - _nodeRadius - _minY,
                  child: DraggableNode(
                    node: node,
                    nodeRadius: _nodeRadius,
                    isPinned: _pinnedNodes.contains(node.id),
                    onDragStart: () => _handleNodeDragStart(node.id),
                    onDrag: (details) => _handleNodeDrag(node.id, details),
                    onDragEnd: () => _handleNodeDragEnd(node.id),
                    onDoubleTap: () => _unpinNode(node.id),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class DraggableNode extends StatelessWidget {
  final ConceptNode node;
  final double nodeRadius;
  final bool isPinned;
  final VoidCallback onDragStart;
  final ValueChanged<DragUpdateDetails> onDrag;
  final VoidCallback onDragEnd;
  final VoidCallback onDoubleTap;

  const DraggableNode({
    super.key,
    required this.node,
    required this.nodeRadius,
    required this.isPinned,
    required this.onDragStart,
    required this.onDrag,
    required this.onDragEnd,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => onDragStart(),
      onPanUpdate: onDrag,
      onPanEnd: (_) => onDragEnd(),
      onDoubleTap: onDoubleTap,
      child: Container(
        width: nodeRadius * 2,
        height: nodeRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: node.type.toLowerCase() == 'topic'
              ? Colors.blue.shade600
              : Colors.green.shade600,
          border: isPinned 
              ? Border.all(color: Colors.orange, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  node.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: node.type.toLowerCase() == 'topic' 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
            if (isPinned)
              Positioned(
                top: 2,
                right: 2,
                child: Icon(
                  Icons.push_pin,
                  size: 14,
                  color: Colors.orange.shade300,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MindMapPainter extends CustomPainter {
  final List<ConceptNode> nodes;
  final List<ConceptEdge> edges;
  final Map<String, Offset> nodePositions;
  final double nodeRadius;
  final double offsetX;
  final double offsetY;

  MindMapPainter({
    required this.nodes,
    required this.edges,
    required this.nodePositions,
    required this.nodeRadius,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint edgePaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final source = nodePositions[edge.sourceId];
      final target = nodePositions[edge.targetId];

      if (source != null && target != null) {
        final adjustedSource = source.translate(offsetX, offsetY);
        final adjustedTarget = target.translate(offsetX, offsetY);
        
        canvas.drawLine(adjustedSource, adjustedTarget, edgePaint);

        // Ok ucu
        final vector = adjustedTarget - adjustedSource;
        final length = vector.distance;
        final direction = length > 0 
            ? Offset(vector.dx / length, vector.dy / length) 
            : Offset.zero;
        final arrowSize = 10.0;
        final arrowPoint = adjustedTarget - direction * nodeRadius;

        final p1 = arrowPoint - Offset(direction.dy * arrowSize, -direction.dx * arrowSize) * 0.5;
        final p2 = arrowPoint + Offset(direction.dy * arrowSize, -direction.dx * arrowSize) * 0.5;

        final arrowPath = Path()
          ..moveTo(arrowPoint.dx, arrowPoint.dy)
          ..lineTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..close();

        canvas.drawPath(arrowPath, Paint()
          ..color = edgePaint.color
          ..style = PaintingStyle.fill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MindMapPainter oldDelegate) {
    return oldDelegate.nodePositions != nodePositions;
  }
}