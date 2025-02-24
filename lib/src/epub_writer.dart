import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'dart:convert' as convert;
import 'package:epubx/src/utils/zip_path_utils.dart';
import 'package:epubx/src/writers/epub_package_writer.dart';

import 'entities/epub_book.dart';
import 'entities/epub_byte_content_file.dart';
import 'entities/epub_text_content_file.dart';

class EpubWriter {
  static const _container_file =
      '<?xml version="1.0"?><container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles></container>';

  // Creates a Zip Archive of an EpubBook
  static Archive _createArchive(EpubBook book) {
    var arch = Archive();
    // 将字符串编码为 Uint8List
    Uint8List mimetypeContent = Uint8List.fromList(utf8.encode('application/epub+zip'));
    // 创建 ArchiveFile 对象
    var mimetypeFile = ArchiveFile('mimetype', mimetypeContent.length, mimetypeContent)..compression = CompressionType.none; // 设置为不压缩
    arch.addFile(mimetypeFile);
   
    // Add Container file
    arch.addFile(ArchiveFile('META-INF/container.xml', _container_file.length, convert.utf8.encode(_container_file)));

    // Add all content to the archive
    book.Content!.AllFiles!.forEach((name, file) {
      List<int>? content;

      if (file is EpubByteContentFile) {
        content = file.Content;
      } else if (file is EpubTextContentFile) {
        content = convert.utf8.encode(file.Content!);
      }

      arch.addFile(ArchiveFile(ZipPathUtils.combine(book.Schema!.ContentDirectoryPath, name)!, content!.length, content));
    });

    // Generate the content.opf file and add it to the Archive
    var contentopf = EpubPackageWriter.writeContent(book.Schema!.Package!);

    arch.addFile(ArchiveFile(ZipPathUtils.combine(book.Schema!.ContentDirectoryPath, 'content.opf')!, contentopf.length, convert.utf8.encode(contentopf)));

    return arch;
  }

  // Serializes the EpubBook into a byte array
  static List<int>? writeBook(EpubBook book) {
    var arch = _createArchive(book);

    return ZipEncoder().encode(arch);
  }
}
