#include <fstream>
#include <iostream>
#include <sstream>
#include <iomanip>

#include <vector>
#include <string>
#include <map>
#include <libxml/xmlreader.h>
#include <libxml/xmlwriter.h>

#include "io_kml.h"

#include <math.h>
#include "err/err.h"

using namespace std;

/* 
KML writing:
- waypoints, tracks, no maps.
- waypoint lists:
  * in separate folders
  * name -> <name> attribute
- waypoints:
  * name -> <name>
  * comm -> <description>
  * x,y,z -> <coordinates>
- tracks:
  * name -> <description>
  * open/closed track support
*/

void
write_kml (const char* filename, const GeoData & data, const Opt & opts){

  LIBXML_TEST_VERSION

  // create XML writer
  xmlTextWriterPtr writer =
    xmlNewTextWriterFilename(filename, opts.get<int>("xml_compr", 0));
  if (writer == NULL)
    throw Err() << "write_kml: can't write to file: " << filename;

  if (opts.exists("verbose")) cerr <<
    "Writing KML file: " << filename << endl;

  try {
    // set some parameters
    int indent = opts.get<int>("xml_indent", 1);
    char qchar = opts.get<char>("xml_qchar", '\'');
    xmlChar *ind_str = (xmlChar *)opts.get<std::string>("xml_ind_str", "  ").c_str();

    if (xmlTextWriterSetIndent(writer, indent)<0 ||
        xmlTextWriterSetIndentString(writer, ind_str)<0 ||
        xmlTextWriterSetQuoteChar(writer, qchar)<0)
      throw "setting xml writer parameters";

    // start XML document
    if (xmlTextWriterStartDocument(writer, "1.0", "UTF-8", NULL)<0)
      throw "starting the xml document";

    // start KML element.
    // BAD_CAST converts (const char*) to BAD_CAST.
    if (xmlTextWriterStartElement(writer, BAD_CAST "kml")<0 ||
        xmlTextWriterWriteAttribute(writer,
          BAD_CAST "xmlns", BAD_CAST "http://earth.google.com/kml/2.1")<0)
      throw "starting <kml> element";

    if (xmlTextWriterStartElement(writer, BAD_CAST "Document")<0)
      throw "starting <Document> element";

    // Writing waypoints:
    for (int i = 0; i < data.wpts.size(); i++) {
      if (xmlTextWriterStartElement(writer, BAD_CAST "Folder")<0)
        throw "starting <Folder> element";

      string name = data.wpts[i].opts.get<string>("name");
      if (name != "") {
        if (xmlTextWriterStartElement(writer, BAD_CAST "name")<0)
          throw "starting <name> element";
        if (xmlTextWriterWriteFormatCDATA(writer, "%s", name.c_str())<0)
          throw "writing <name> element";
        if (xmlTextWriterEndElement(writer) < 0)
          throw "closing <name> element";
      }

      GeoWptList::const_iterator wp;
      for (wp = data.wpts[i].begin(); wp != data.wpts[i].end(); ++wp) {
        if (xmlTextWriterStartElement(writer, BAD_CAST "Placemark")<0)
          throw "starting <Placemark> element";

        string name = wp->opts.get<string>("name");
        if (name != "") {
          if (xmlTextWriterStartElement(writer, BAD_CAST "name")<0)
            throw "starting <name> element";
          if (xmlTextWriterWriteFormatCDATA(writer, "%s", name.c_str())<0)
            throw "writing <name> element";
          if (xmlTextWriterEndElement(writer) < 0)
            throw "closing <name> element";
         }

        string comm = wp->opts.get<string>("comm");
        if (comm != "") {
          if (xmlTextWriterStartElement(writer, BAD_CAST "description")<0)
            throw "starting <description> element";
          if (xmlTextWriterWriteFormatCDATA(writer, "%s", comm.c_str())<0)
            throw "writing <description> element";
          if (xmlTextWriterEndElement(writer) < 0)
            throw "closing <description> element";
        }

        if (xmlTextWriterStartElement(writer, BAD_CAST "Point")<0)
          throw "starting <Point> element";

        if (xmlTextWriterWriteFormatElement(writer,
           BAD_CAST "coordinates", "%.7f,%.7f,%.2f",
               wp->x, wp->y, wp->z)<0)
          throw "writing <coordinates> element";

        if (xmlTextWriterEndElement(writer) < 0)
          throw "closing <Point> element";

        if (xmlTextWriterEndElement(writer) < 0)
          throw "closing <Placemark> element";
      }
      if (xmlTextWriterEndElement(writer) < 0)
        throw "closing <Folder> element";
    }

    // Writing tracks:
    for (int i = 0; i < data.trks.size(); ++i) {
      if (xmlTextWriterStartElement(writer, BAD_CAST "Placemark")<0)
        throw "starting <Placemark> element";

      string name = data.trks[i].opts.get<string>("name");
      if (name != "") {
        if (xmlTextWriterStartElement(writer, BAD_CAST "name")<0)
          throw "starting <name> element";
        if (xmlTextWriterWriteFormatCDATA(writer, "%s",
               data.trks[i].opts.get<string>("name").c_str())<0)
          throw "writing <name> element";
        if (xmlTextWriterEndElement(writer) < 0)
          throw "closing <name> element";
      }

      if (xmlTextWriterStartElement(writer, BAD_CAST "MultiGeometry")<0)
        throw "starting <MultiGeometry> element";

      GeoTrk::const_iterator tp;
      string linename;
      for (tp = data.trks[i].begin(); tp != data.trks[i].end(); ++tp) {
        linename = data.trks[i].opts.get<std::string>("type")=="closed"? "Polygon":"LineString";

        if (tp->start || tp == data.trks[i].begin()) {
          if (tp != data.trks[i].begin()) {
            if (xmlTextWriterWriteFormatString(writer, "\n")<0)
              throw "writing <coordinates> element";
            if (xmlTextWriterEndElement(writer) < 0) throw "closing <coordinates> element";
            if (xmlTextWriterEndElement(writer) < 0) throw "closing line element";
          }
          if (xmlTextWriterStartElement(writer, BAD_CAST linename.c_str())<0)
            throw "starting line element";
          if (xmlTextWriterWriteFormatElement(writer,
             BAD_CAST "tessellate", "%d", 1)<0)
            throw "writing <tessellate> element";

          if (xmlTextWriterStartElement(writer, BAD_CAST "coordinates")<0)
            throw "starting coordinates element";
        }

        if (xmlTextWriterWriteFormatString(writer,
           "\n%.7f,%.7f,%.2f", tp->x, tp->y, tp->z)<0)
          throw "writing <coordinates> element";
      }
      if (xmlTextWriterWriteFormatString(writer, "\n")<0)
        throw "writing <coordinates> element";
      if (xmlTextWriterEndElement(writer) < 0) throw "closing <coordinates> element";
      if (xmlTextWriterEndElement(writer) < 0) throw "closing line element";
      if (xmlTextWriterEndElement(writer) < 0) throw "closing <MultiGeometry> element";
      if (xmlTextWriterEndElement(writer) < 0) throw "closing <Placemark> element";
    }
    if (xmlTextWriterEndElement(writer) < 0) throw "closing <Document> element";
    if (xmlTextWriterEndElement(writer) < 0) throw "closing <kml> element";
    if (xmlTextWriterEndDocument(writer) < 0) throw "closing xml document";

  }
  catch (const char *c){
    xmlFreeTextWriter(writer);
    throw Err() << "write_gpx: error in " << c;
  }

  // free resources
  xmlFreeTextWriter(writer);

  return;
}

#define TYPE_ELEM      1
#define TYPE_ELEM_END 15
#define TYPE_TEXT      3
#define TYPE_CDATA     4
#define TYPE_SWS      14

#define NAMECMP(x) (xmlStrcasecmp(name,(const xmlChar *)x)==0)
#define GETATTR(x) (const char *)xmlTextReaderGetAttribute(reader, (const xmlChar *)x)
#define GETVAL     (const char *)xmlTextReaderConstValue(reader)

int
read_text_node(xmlTextReaderPtr reader, const char * nn, string & str){
  int ret=1;
  str.clear();
  while(1){
    ret =xmlTextReaderRead(reader);
    if (ret != 1) break;

    const xmlChar *name = xmlTextReaderConstName(reader);
    int type = xmlTextReaderNodeType(reader);

    if (type == TYPE_SWS) continue;
    else if (type == TYPE_TEXT || type == TYPE_CDATA) str += GETVAL;
    else if (NAMECMP(nn) && (type == TYPE_ELEM_END)) break;
    else cerr << "Warning: Unknown node \"" << name << "\" in text node (type: " << type << ")\n";
  }
  return ret;
}

int
read_point_node(xmlTextReaderPtr reader, GeoWpt & ww){
  int ret=1;
  while(1){
    ret =xmlTextReaderRead(reader);
    if (ret != 1) break;

    const xmlChar *name = xmlTextReaderConstName(reader);
    int type = xmlTextReaderNodeType(reader);

    if (type == TYPE_SWS) continue;
    else if (NAMECMP("coordinates") && (type == TYPE_ELEM)){
      string str;
      ret=read_text_node(reader, "coordinates", str);
      if (ret != 1) break;
      char s1,s2;
      istringstream s(str);
      s >> std::ws >> ww.x >> std::ws >> s1 >>
           std::ws >> ww.y >> std::ws >> s2 >>
           std::ws >> ww.z >> std::ws;
      if (s1!=',' || s2!=','){
        cerr << "Warning: Coord error\n";
        ret=0;
        break;
      }
    }
    else if (NAMECMP("Point") && (type == TYPE_ELEM_END)){
      break;
    }
    else {
      cerr << "Warning: Unknown node \"" << name << "\" in Point (type: " << type << ")\n";
    }
  }
  return ret;
}

int
read_linestring_node(xmlTextReaderPtr reader, GeoTrk & T){
  int ret=1;
  while(1){
    ret =xmlTextReaderRead(reader);
    if (ret != 1) break;

    const xmlChar *name = xmlTextReaderConstName(reader);
    int type = xmlTextReaderNodeType(reader);

    if (type == TYPE_SWS) continue;
    else if (NAMECMP("tessellate") && (type == TYPE_ELEM)){
      string str;
      ret=read_text_node(reader, "tessellate", str);
      if (ret != 1) break;
    }
    else if (NAMECMP("coordinates") && (type == TYPE_ELEM)){
      string str;
      ret=read_text_node(reader, "coordinates", str);
      if (ret != 1) break;
      char s1,s2;
      istringstream s(str);
      GeoTpt tp;
      tp.start=true;
      while (!s.eof()){
        s >> std::ws >> tp.x >> std::ws >> s1 >>
             std::ws >> tp.y >> std::ws >> s2 >>
             std::ws >> tp.z >> std::ws;
        if (s1!=',' || s2!=','){
          cerr << "Warning: Coord error\n";
          break;
        }
        T.push_back(tp);
        tp.start=false;
      }
    }
    else if (NAMECMP("LineString") && (type == TYPE_ELEM_END)){
      break;
    }
    else {
      cerr << "Warning: Unknown node \"" << name << "\" in LineString (type: " << type << ")\n";
    }
  }
  return ret;
}

/* same as Linestring, but for closed lines */
int
read_polygon_node(xmlTextReaderPtr reader, GeoTrk & T){
  int ret=1;
  T.opts.put("type", "closed");

  while(1){
    ret =xmlTextReaderRead(reader);
    if (ret != 1) break;

    const xmlChar *name = xmlTextReaderConstName(reader);
    int type = xmlTextReaderNodeType(reader);

    if (type == TYPE_SWS) continue;
    else if (NAMECMP("tessellate") && (type == TYPE_ELEM)){
      string str;
      ret=read_text_node(reader, "tessellate", str);
      if (ret != 1) break;
    }
    else if (NAMECMP("coordinates") && (type == TYPE_ELEM)){
      string str;
      ret=read_text_node(reader, "coordinates", str);
      if (ret != 1) break;
      char s1,s2;
      istringstream s(str);
      GeoTpt tp;
      tp.start=true;
      while (!s.eof()){
        s >> std::ws >> tp.x >> std::ws >> s1 >>
             std::ws >> tp.y >> std::ws >> s2 >>
             std::ws >> tp.z >> std::ws;
        if (s1!=',' || s2!=','){
          cerr << "Warning: Coord error\n";
          break;
        }
        T.push_back(tp);
        tp.start=false;
      }
    }
    else if (NAMECMP("Polygon") && (type == TYPE_ELEM_END)){
      break;
    }
    else {
      cerr << "Warning: Unknown node \"" << name << "\" in Polygon (type: " << type << ")\n";
    }
  }
  return ret;
}


int
read_gx_track_node(xmlTextReaderPtr reader, GeoTrk & T){
  int ret=1;
  T = GeoTrk();
  while(1){
    ret =xmlTextReaderRead(reader);
    if (ret != 1) break;

    const xmlChar *name = xmlTextReaderConstName(reader);
    int type = xmlTextReaderNodeType(reader);

    if (type == TYPE_SWS) continue;
    else if (NAMECMP("when") && (type == TYPE_ELEM)){
      string str;
      ret=read_text_node(reader, "when", str);
      if (ret != 1) break;
    }
    else if (NAMECMP("gx:coord") && (type == TYPE_ELEM)){
      string str;
      ret=read_text_node(reader, "gx:coord", str);
      if (ret != 1) break;
      istringstream s(str);
      GeoTpt tp;
      s >> std::ws >> tp.x >> std::ws
        >> std::ws >> tp.y >> std::ws
        >> std::ws >> tp.z >> std::ws;
      T.push_back(tp);
    }
    else if (NAMECMP("gx:Track") && (type == TYPE_ELEM_END)){
      break;
    }
    else {
      cerr << "Warning: Unknown node \"" << name << "\" in gx:Track (type: " << type << ")\n";
    }
  }
  if (T.size()) T[0].start=true;
  return ret;
}

int
read_multigeometry_node(xmlTextReaderPtr reader, GeoTrk & T){
  int ret=1;
  while(1){
    ret =xmlTextReaderRead(reader);
    if (ret != 1) break;

    const xmlChar *name = xmlTextReaderConstName(reader);
    int type = xmlTextReaderNodeType(reader);

    if (type == TYPE_SWS) continue;
    else if (NAMECMP("LineString") && (type == TYPE_ELEM)){
      ret=read_linestring_node(reader, T);
      if (ret != 1) break;
    }
    else if (NAMECMP("Polygon") && (type == TYPE_ELEM)){
      ret=read_polygon_node(reader, T);
      if (ret != 1) break;
    }
    else if (NAMECMP("MultiGeometry") && (type == TYPE_ELEM_END)){
      break;
    }
    else {
      cerr << "Warning: Unknown node \"" << name << "\" in MultiGeometry (type: " << type << ")\n";
    }
  }
  return ret;
}

int
read_placemark_node(xmlTextReaderPtr reader,
     GeoWptList & W, GeoTrk & T, GeoMapList & M){

  GeoWpt ww;
  GeoMap mm;
  T = GeoTrk();

  int ot=-1;
  bool skip=false;
  int ret=1;

  while(1){
    ret =xmlTextReaderRead(reader);
    if (ret != 1) break;

    const xmlChar *name = xmlTextReaderConstName(reader);
    int type = xmlTextReaderNodeType(reader);

    if (type == TYPE_SWS) continue;
    // Skip some blocks
    else if (NAMECMP("Camera") || NAMECMP("LookAt") ||
             NAMECMP("styleUrl") || NAMECMP("visibility")){
      if (type == TYPE_ELEM) skip=true;
      if (type == TYPE_ELEM_END) skip=false;
    }
    else if (skip) continue;

    else if (NAMECMP("name") && (type == TYPE_ELEM)){
      string str;
      ret=read_text_node(reader, "name", str);
      if (ret != 1) break;
      ww.opts.put("name", str);
       T.opts.put("name", str);
      mm.name = str;
    }

    else if (NAMECMP("description") && (type == TYPE_ELEM)){
      string str;
      ret=read_text_node(reader, "description", str);
      if (ret != 1) break;
      ww.opts.put("name", str);
       T.opts.put("name", str);
      mm.name = str;
    }
//    else if (NAMECMP("TimeStamp") && (type == TYPE_ELEM)){
//    }
    else if (NAMECMP("Point") && (type == TYPE_ELEM)){
      ot=0;
      ret=read_point_node(reader, ww);
      if (ret != 1) break;
    }
    else if (NAMECMP("LineString") && (type == TYPE_ELEM)){
      ot=1;
      ret=read_linestring_node(reader, T);
      if (ret != 1) break;
    }
    else if (NAMECMP("Polygon") && (type == TYPE_ELEM)){
      ot=1;
      ret=read_polygon_node(reader, T);
      if (ret != 1) break;
    }
    else if (NAMECMP("MultiGeometry") && (type == TYPE_ELEM)){
      ot=1;
      ret=read_multigeometry_node(reader, T);
      if (ret != 1) break;
    }
    else if (NAMECMP("gx:Track") && (type == TYPE_ELEM)){
      ot=1;
      ret=read_gx_track_node(reader, T);
      if (ret != 1) break;
    }
    else if (NAMECMP("Placemark") && (type == TYPE_ELEM_END)){
      break;
    }
    else {
      cerr << "Warning: Unknown node \"" << name << "\" in Placemark (type: " << type << ")\n";
    }
  }
  if (ot==0) W.push_back(ww);
  return ret;
}



int
read_folder_node(xmlTextReaderPtr reader, GeoData & data){ // similar to document node
  GeoWptList W;
  GeoTrk     T;
  GeoMapList M;
  bool skip=false;
  int ret=1;
  while(1){
    ret =xmlTextReaderRead(reader);
    if (ret != 1) break;

    const xmlChar *name = xmlTextReaderConstName(reader);
    int type = xmlTextReaderNodeType(reader);

    if (type == TYPE_SWS) continue;

    // skip some blocks
    else if (NAMECMP("visibility") || NAMECMP("open")){
      if (type == TYPE_ELEM) skip=true;
      if (type == TYPE_ELEM_END) skip=false;
    }
    else if (skip) continue;

    else if (NAMECMP("name") && (type == TYPE_ELEM)){
      string str;
      ret=read_text_node(reader, "name", str);
      if (ret != 1) break;
      W.opts.put("name", str);
      T.opts.put("name", str);
      M.opts.put("name", str);
    }
    else if (NAMECMP("Placemark") && (type == TYPE_ELEM)){
      ret=read_placemark_node(reader, W, T, M);
      if (T.size()) data.trks.push_back(T);
      if (ret != 1) break;
    }
    else if (NAMECMP("Folder") && (type == TYPE_ELEM)){
      ret=read_folder_node(reader, data);
      if (ret != 1) break;
    }
    else if (NAMECMP("Folder") && (type == TYPE_ELEM_END)){
      break;
    }
    else {
      cerr << "Warning: Unknown node \"" << name << "\" in Folder (type: " << type << ")\n";
    }
  }
  if (W.size()) data.wpts.push_back(W);
  if (M.size()) data.maps.push_back(M);
  return ret;
}

int
read_document_node(xmlTextReaderPtr reader, GeoData & data){
  bool skip=false;
  GeoWptList W;
  GeoTrk     T;
  GeoMapList M;
  int ret=1;
  while(1){
    ret =xmlTextReaderRead(reader);
    if (ret != 1) break;

    const xmlChar *name = xmlTextReaderConstName(reader);
    int type = xmlTextReaderNodeType(reader);

    if (type == TYPE_SWS) continue;
    // Skip some blocks
    else if (NAMECMP("Style") || NAMECMP("StyleMap") ||
             NAMECMP("open") || NAMECMP("visibility") ||
             NAMECMP("name") || NAMECMP("Snippet") ||
             NAMECMP("LookAt")){
      if (type == TYPE_ELEM) skip=true;
      if (type == TYPE_ELEM_END) skip=false;
    }
    else if (skip) continue;
    else if (NAMECMP("name") && (type == TYPE_ELEM)){
      string str;
      ret=read_text_node(reader, "name", str);
      if (ret != 1) break;
      W.opts.put("name", str);
      T.opts.put("name", str);
      M.opts.put("name", str);
    }
    else if (NAMECMP("Placemark") && (type == TYPE_ELEM)){
      ret=read_placemark_node(reader, W, T, M);
      if (ret != 1) break;
    }
    else if (NAMECMP("Folder") && (type == TYPE_ELEM)){
      ret=read_folder_node(reader, data);
      if (ret != 1) break;
    }
    else if (NAMECMP("Document") && (type == TYPE_ELEM_END)){
      break;
    }
    else {
      cerr << "Warning: Unknown node \"" << name << "\" in Document (type: " << type << ")\n";
    }
  }
  if (W.size()) data.wpts.push_back(W);
  if (T.size()) data.trks.push_back(T);
  if (M.size()) data.maps.push_back(M);
  return ret;
}

int
read_kml_node(xmlTextReaderPtr reader, GeoData & data){
  while(1){
    int ret =xmlTextReaderRead(reader);
    if (ret != 1) return ret;

    const xmlChar *name = xmlTextReaderConstName(reader);
    int type = xmlTextReaderNodeType(reader);

    if (type == TYPE_SWS) continue;

    else if (NAMECMP("Document") && (type == TYPE_ELEM)){
      ret=read_document_node(reader, data);
      if (ret != 1) return ret;
    }

    else if (NAMECMP("kml") && (type == TYPE_ELEM_END)){
      break;
    }

    else {
      cerr << "Warning: Unknown node \"" << name << "\" in kml (type: " << type << ")\n";
    }
  }
  return 1;
}


void
read_kml(const char* filename, GeoData & data, const Opt & opts) {

  LIBXML_TEST_VERSION

  xmlTextReaderPtr reader;
  int ret;

  reader = xmlReaderForFile(filename, NULL, 0);
  if (reader == NULL)
    throw Err() << "Can't open KML file: " << filename;

  if (opts.exists("verbose")) cerr <<
    "Reading KML file: " << filename << endl;

  // parse file
  while (1){
    ret = xmlTextReaderRead(reader);
    if (ret!=1) break;

    const xmlChar *name = xmlTextReaderConstName(reader);
    int type = xmlTextReaderNodeType(reader);
    if (NAMECMP("kml") && (type == TYPE_ELEM))
      ret = read_kml_node(reader, data);
    if (ret!=1) break;
  }

  // free resources
  xmlFreeTextReader(reader);
  xmlCleanupParser();
  xmlMemoryDump();

  if (ret != 0) throw Err() << "Can't parse KML file: " << filename;
}
