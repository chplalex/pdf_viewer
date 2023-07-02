import 'package:chakre_pdf_viewer/chakre_pdf_viewer.dart';
import 'package:flutter/material.dart';

class PDFListViewer extends StatefulWidget {
  final PDFDocument document;
  List<Image?>? _images;
  final bool preload;
  double? _loadingPageHeight;

  /// Shows PDF of multiple pages in list mode
  PDFListViewer({
    Key? key,
    required this.document,
    this.preload = false,
    double loadingPageHeight = 400,
  }) : super(key: key) {
    _loadingPageHeight = loadingPageHeight;
  }

  @override
  _PDFListViewerState createState() => _PDFListViewerState();
}

class _PDFListViewerState extends State<PDFListViewer> {
  bool _preloaded = false;

  @override
  void initState() {
    super.initState();
    widget._images =
        List<Image?>.filled(widget.document.count!, null, growable: true);
    if (widget.preload) {
      Future.delayed(Duration.zero, () async {
        await widget.document.preloadImages();
        widget._images = widget.document.images;
        _preloaded = true;
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (var i = 0; i < widget._images!.length; i++) {
      widget._images![i]!.image.evict();
      widget._images![i] = null;
    }
    widget._images = null;
    widget.document.clearImageCache();
    widget.document.clearFileCache();
    super.dispose();
  }

  Future<Image?>? _loadPage(int index) async {
    if (index < 0 || index >= widget._images!.length) return null;
    if (widget._images![index] != null) return widget._images![index];
    final data = await widget.document.getImage(page: index + 1);
    widget._images![index] = data;
    return widget._images![index];
  }

  @override
  Widget build(BuildContext context) {
    return widget.preload
        ? _preloaded
            ? ListView.builder(
                itemCount: widget.document.count,
                itemBuilder: (context, index) {
                  return widget._images![index]!;
                })
            : Center(
                child: CircularProgressIndicator(),
              )
        : ListView.builder(
            itemCount: widget.document.count,
            itemBuilder: (context, index) => FutureBuilder(future: () async {
              return await _loadPage(index);
            }(), builder: (context, snapShot) {
              if (snapShot.hasData) {
                return snapShot.data as Image;
              } else {
                return Container(
                  height: widget._loadingPageHeight,
                  width: double.maxFinite,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
            }),
          );
  }
}
