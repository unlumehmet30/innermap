// lib/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:innermap/models/concept_edge.dart';
import 'package:innermap/models/concept_node.dart';
import 'package:innermap/core/services/storage_service.dart';
import 'package:innermap/models/map_entry.dart';
import 'dart:math';
import 'dart:convert';

// --- MAPSCREEN: StatefulWidget ve InteractiveViewer İle Etkileşim ---
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
  final double _nodeRadius = 40.0;
  String? _draggedNodeId;
  double _canvasWidth = 0;
  double _canvasHeight = 0;
  final StorageService _storageService = StorageService(); 

  // Fiziksel hareket ve etkileşim için gereken diğer değişkenler
  final Map<String, Offset> _nodeVelocities = {};
  final Set<String> _pinnedNodes = {};
  late AnimationController _animationController;
  final double _repulsionStrength = 1000.0;
  final double _attractionStrength = 0.005;
  final double _damping = 0.75;
  final double _centerForce = 0.0005;
  double _minX = 0, _maxX = 0, _minY = 0, _maxY = 0;
  final double _padding = 100.0;
  
  TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    // Fizik motoru animasyonu
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 32),
    )..addListener(_updatePhysics);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNodePositions();
      // Fizik motorunu başlatmak için (istenirse aktif edilebilir)
      // _animationController.repeat(); 
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformController.dispose();
    super.dispose();
  }
  
  // --- Yardımcı Fonksiyon: Başlangıç Pozisyonlarını Hesaplama (POZİSYON KORUMA) ---
  void _initializeNodePositions() {
    if (!mounted || widget.nodes.isEmpty) return;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double centerX = screenWidth / 2;
    final double centerY = screenHeight / 2;
    
    double minX = centerX, maxX = centerX;
    double minY = centerY, maxY = centerY;
    int nodeCount = widget.nodes.length - 1;
    double angleStep = nodeCount > 0 ? 2 * pi / nodeCount : 0; 
    double radius = 250.0; 

    setState(() {
      // KRİTİK: Kayıtlı X/Y'yi öncelikli kullanma mantığı
      for (int i = 0; i < widget.nodes.length; i++) {
        final ConceptNode node = widget.nodes[i];
        
        Offset position;
        
        // 🚨 YÜKLEME MANTIĞI: Eğer Node objesi kayıtlı X ve Y içeriyorsa (Yüklemeden geliyorsa)
        if (node.x != null && node.y != null) {
          position = Offset(node.x!, node.y!); // <-- KAYITLI POZİSYONU KULLAN
        } 
        // Kayıtlı pozisyon yoksa, Dairesel Yerleşim kullan (İlk kez üretiliyorsa)
        else if (i == 0) {
          position = Offset(centerX, centerY);
        } else {
          final double angle = i * angleStep;
          position = Offset(centerX + radius * cos(angle), centerY + radius * sin(angle));
        }

        _nodePositions[node.id] = position;
        _nodeVelocities[node.id] = Offset.zero; 

        // Kaydırma alanı için sınırları güncelle
        minX = min(minX, position.dx);
        maxX = max(maxX, position.dx);
        minY = min(minY, position.dy);
        maxY = max(maxY, position.dy);
      }
      
      // Kanvas Boyutunu Hesaplama
      const double padding = 150.0; 
      _canvasWidth = max((maxX - minX).abs() + padding, screenWidth);
      _canvasHeight = max((maxY - minY).abs() + padding, screenHeight);
      
      _updateBounds(initial: true);
    });
  }
  
  // --- FİZİK GÜNCELLEME (Kalan Kod) ---
  void _updatePhysics() {
    if (_nodePositions.isEmpty || _draggedNodeId != null) return; 
    if (!mounted) return;

    setState(() {
      final Map<String, Offset> forces = {};
      for (final node in widget.nodes) {
        forces[node.id] = Offset.zero;
      }

      // 1. İtme Kuvveti (Repulsion) ve 2. Çekim Kuvveti (Attraction) hesaplamaları
      for (int i = 0; i < widget.nodes.length; i++) {
        for (int j = i + 1; j < widget.nodes.length; j++) {
          final node1 = widget.nodes[i];
          final node2 = widget.nodes[j];
          final pos1 = _nodePositions[node1.id];
          final pos2 = _nodePositions[node2.id];
          if (pos1 == null || pos2 == null) continue;
          
          final delta = pos1 - pos2;
          final distance = max(delta.distance, 10.0);
          if (distance.isNaN || distance.isInfinite) continue;
          
          final forceMagnitude = _repulsionStrength / (distance * distance);
          if (forceMagnitude.isNaN || forceMagnitude.isInfinite) continue;
          
          final force = delta / distance * forceMagnitude;
          
          if (!force.dx.isNaN && !force.dy.isNaN) {
            forces[node1.id] = forces[node1.id]! + force;
            forces[node2.id] = forces[node2.id]! - force;
          }
        }
      }

      for (final edge in widget.edges) {
        final source = _nodePositions[edge.sourceId];
        final target = _nodePositions[edge.targetId];
        
        if (source != null && target != null) {
          final delta = target - source;
          final distance = delta.distance;
          
          if (distance.isNaN || distance.isInfinite) continue;
          
          final force = delta * _attractionStrength * distance;
          
          if (!force.dx.isNaN && !force.dy.isNaN) {
            forces[edge.sourceId] = forces[edge.sourceId]! + force;
            forces[edge.targetId] = forces[edge.targetId]! - force;
          }
        }
      }

      // 3. Merkez Çekim Kuvveti (Gravity)
      final center = Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2);
      
      for (final node in widget.nodes) {
        final pos = _nodePositions[node.id];
        if (pos == null) continue;
        final toCenter = center - pos;
        if (!toCenter.dx.isNaN && !toCenter.dy.isNaN) {
          forces[node.id] = forces[node.id]! + toCenter * _centerForce;
        }
      }

      // Kuvvetleri Uygula ve Pozisyonları Güncelle
      for (final node in widget.nodes) {
        if (node.id == _draggedNodeId || _pinnedNodes.contains(node.id)) continue;
        final force = forces[node.id];
        if (force == null || force.dx.isNaN || force.dy.isNaN) continue;
        
        final currentVelocity = _nodeVelocities[node.id] ?? Offset.zero;
        final newVelocity = (currentVelocity + force) * _damping;
        
        final speed = newVelocity.distance;
        if (speed > 10.0) { 
          _nodeVelocities[node.id] = newVelocity / speed * 10.0;
        } else {
          _nodeVelocities[node.id] = newVelocity;
        }
        
        final currentPosition = _nodePositions[node.id];
        if (currentPosition == null) continue;
        
        final newPosition = currentPosition + _nodeVelocities[node.id]!;
        
        if (!newPosition.dx.isNaN && !newPosition.dy.isNaN) {
          _nodePositions[node.id] = newPosition;
        }
      }
      
      _updateBounds();
    });
  }

  // --- SINIRLARI GÜNCELLEME ---
  void _updateBounds({bool initial = false}) {
    if (_nodePositions.isEmpty || !mounted) return;
    
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
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    if (minX.isInfinite || maxX.isInfinite || minY.isInfinite || maxY.isInfinite) {
      _minX = 0; _maxX = screenWidth; _minY = 0; _maxY = screenHeight;
    } else {
      _minX = minX - _padding;
      _maxX = maxX + _padding;
      _minY = minY - _padding;
      _maxY = maxY + _padding;
    }
    
    if (initial) {
      setState(() {
        _canvasWidth = max(_maxX - _minX, screenWidth);
        _canvasHeight = max(_maxY - _minY, screenHeight);
      });
    }
  }


  // --- KAYDETME İŞLEVİ (POZİSYON KORUMA) ---
  void _saveMap() async {
    final List<Map<String, dynamic>> nodesWithPositions = [];
    
    for (final node in widget.nodes) {
        final Offset? currentPosition = _nodePositions[node.id];
        Map<String, dynamic> nodeJson = node.toJson();
        
        // KRİTİK: Düğümün JSON'una güncel X ve Y pozisyonlarını ekle
        if (currentPosition != null) {
            nodeJson['x'] = currentPosition.dx;
            nodeJson['y'] = currentPosition.dy;
        }
        nodesWithPositions.add(nodeJson);
    }
    
    final Map<String, dynamic> mapData = {
        'nodes': nodesWithPositions, 
        'edges': widget.edges.map((edge) => edge.toJson()).toList()
    };
    
    final String jsonDataString = json.encode(mapData);

    final String title = widget.nodes.isNotEmpty 
        ? widget.nodes.first.text.substring(0, min(widget.nodes.first.text.length, 30)) 
        : 'Adsız Harita';

    final MapEntry entry = MapEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(), 
      title: title,
      timestamp: DateTime.now(),
      jsonData: jsonDataString,
    );

    await _storageService.saveMapEntry(entry);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Harita Başarıyla Kaydedildi: "$title"')),
      );
    }
  }

  // --- EKRANA SIĞDIRMA İŞLEVİ ---
  void _fitToScreen() {
    if (!mounted || widget.nodes.isEmpty || _nodePositions.isEmpty) return;

    _updateBounds(initial: true);

    final double viewportWidth = MediaQuery.of(context).size.width;
    final double viewportHeight = MediaQuery.of(context).size.height;

    final double mapWidth = _maxX - _minX;
    final double mapHeight = _maxY - _minY;

    if (mapWidth <= 0 || mapHeight <= 0) return;

    final double scaleX = viewportWidth / mapWidth;
    final double scaleY = viewportHeight / mapHeight;
    final double finalScale = min(scaleX, scaleY) * 0.95;

    final double mapCenterX = _minX + mapWidth / 2;
    final double mapCenterY = _minY + mapHeight / 2;
    
    final double viewportCenterX = viewportWidth / 2;
    final double viewportCenterY = viewportHeight / 2;

    final double translateX = viewportCenterX - (mapCenterX * finalScale);
    final double translateY = viewportCenterY - (mapCenterY * finalScale);

    final Matrix4 matrix = Matrix4.identity()
      ..translate(translateX, translateY)
      ..scale(finalScale);

    _transformController.value = matrix;
  }


  // --- HAREKET İŞLEYİCİLERİ ---

  void _handleNodeDragStart(String nodeId) {
    setState(() {
      _draggedNodeId = nodeId;
      _nodeVelocities[nodeId] = Offset.zero;
      _pinnedNodes.add(nodeId); 
    });
  }

  void _handleNodeDrag(String nodeId, DragUpdateDetails details) {
    if (_draggedNodeId == nodeId) {
      setState(() {
        final currentPosition = _nodePositions[nodeId]!;
        final double scaleFactor = _transformController.value.getMaxScaleOnAxis(); 
        
        _nodePositions[nodeId] = currentPosition + details.delta / scaleFactor;
        _nodeVelocities[nodeId] = Offset.zero; 
      });
    }
  }

  void _handleNodeDragEnd(String nodeId) {
    setState(() {
      _draggedNodeId = null;
      _nodeVelocities[nodeId] = Offset.zero;
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
            icon: const Icon(Icons.save),
            onPressed: _saveMap,
            tooltip: 'Haritayı Kaydet',
          ),
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
            icon: const Icon(Icons.zoom_out_map),
            tooltip: 'Sığdır',
            onPressed: _fitToScreen,
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
              // 1. Bağlantıları Çiz (CustomPainter)
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

              // 2. Düğümleri Widget Olarak Çiz (Ön Plan)
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

// --- DraggableNode: Sürükleme ve Görünüm ---
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

// --- MindMapPainter: Bağlantıları Çizme ---
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

        final vector = adjustedTarget - adjustedSource;
        final double length = vector.distance;
        final direction = length > 0 
            ? Offset(vector.dx / length, vector.dy / length) 
            : Offset.zero;
        final arrowSize = 10.0;
        final arrowPoint = adjustedTarget - direction * nodeRadius;

        final p1 = arrowPoint - Offset(direction.dy * arrowSize, -direction.dx * arrowSize) * 0.5;
        final p2 = arrowPoint + Offset(direction.dy * arrowSize, -direction.dx * arrowSize) * 0.5;

        final Path arrowPath = Path()
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