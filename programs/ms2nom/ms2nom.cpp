#include <cstring>
#include "geo_nom/geo_nom.h"
#include "geom/poly_tools.h"
#include "geom/line_rectcrop.h"
#include "getopt/getopt.h"
#include "getopt/help_printer.h"
#include "geo_data/conv_geo.h"
#include "geo_data/geo_io.h"
#include "geo_data/geo_utils.h"

using namespace std;

GetOptSet options;

void usage(bool pod=false){

  HelpPrinter pr(pod, options, "ms2nom");
  pr.name("Soviet nomenclature map calculations");

  pr.usage("[-E] [-W] --cover <figure> -s <scale> -- maps covering the figure");
  pr.usage("[-E] [-W] -n <name> -- map range");
  pr.usage("[-E] [-W] -n <name> [--cover_ratio] --cover <figure>  -- check if the map touches given figure");
  pr.usage("[-E] -n <name> -g <geodata>  -- check if the map touches geodata (tracks and points)");
  pr.usage("[-E] [-W] -c -n <name> -- map center");
  pr.usage("[-E] -n <name> --shift [x_shift,y_shift] -- adjacent map");
  pr.usage("[-E] -n <name> -s <scale> -- convert map to a different scale");

  pr.head(1, "Options");
  pr.opts({"NONSTD","HELP","POD"});

  pr.par(
   "Program \"ms2nom\" does some calculations with standard Soviet "
   "nomenclature map names.");

  pr.par(
    "Option --ext (-E) turns on 'extended mode': single sheets (like Q10-001) are allowed "
    "on input and always returned on output; for a single sheet suffix '.<N>x<M>' is "
    "allowed to multiply the range (like n49-001.3x2).");

  pr.par(
    "At the moment combination of --ext and --shift options with such a "
    "\"multiplied\" name returns non-multiplied adjecent sheets. This is not "
    "very useful and maybe changed later.");


  pr.par(
    "If both --cover and --name (-n) options are given "
    "program returns with exit code 0 or 1 depending "
    "on whether the map covers the given figure.");

  pr.par(
    "Soviet nomenclature maps use Pukovo-1942 datum "
    "(+ellps=krass +towgs84=28,-130,-95). By default Pulkovo datum is used "
    "for all calculations. In this datum map corners have round coordinates. "
    "If option --wgs (-W) is given then WGS datum is used  instead of "
    "Pulkovo.");

  pr.par(
    "Supported scales: 1:1000000, 1:500000, 1:200000, 1:100000, 1:50000."
    "Scale can be written in following forms:\n"
    "* 1:1000000, 1:1'000'000, 1000000, 1M, 10km/cm\n"
    "* 1:500000, 1:500'000, 500000, 500k, 5km/cm\n"
    "* 1:200000, 1:200'000, 200000, 100k, 1km/cm\n"
    "* 1:100000, 1:100'000, 100000, 100k, 1km/cm\n"
    "* 1:50000, 1:50'000, 50000, 50k, 500m/cm\n"
  );
  throw Err();
}

int
main(int argc, char **argv){
  try {

    const char *g = "NONSTD";
    options.add("cover",  1,0,g,
      "If --name and --cover_ratio is given show which part of the map is covered by the figure. "
      "If only --name is given, check if the figure touches the map. "
      "Otherwise show map names which cover the figure (--scale should be set). "
      "Figure is a point, rectangle, line, multiline in WGS84 coordinates, "
      "or a geodata file with tracks or points.");

    options.add("cover_ratio",  0,0,g,
      "See --cover option.");

    options.add("scale",  1,'s',g,
      "Set map scale. "
      "Scale should be set when --cover option is used. If used with "
      "--name option then name will be converted to a new scale "
      "instead of printing the range.");

    options.add("name", 1,'n',g,
      "Show coordinate range for a given map.");

    options.add("ext", 0,'E',g,
      "Use 'extended mode': single sheets (like Q10-001) are allowed "
      "on input and always returned on output; for a single sheet "
      "suffix '.<N>x<M>' is allowed to multiply the range (like n49-001.3x2).");

    options.add("wgs", 0,'W',g,
      "Use WGS datum for coordinates (instead of Pulkovo).");

    options.add("center", 0,'c',g,
      "Instead of printing a coordinate range print its central point.");

    options.add("shift", 1,'S',g,
      "Shift a map. Should be used with --name option. Not compatable with --cover option. "
      "Argument is an array of two integer numbers [dx,dy].");

    ms2opt_add_std(options, {"HELP","POD"});

    if (argc<2) usage();
    vector<string> nonopt;
    Opt O = parse_options_all(&argc, &argv, options, {}, nonopt);
    if (O.exists("help")) usage();
    if (O.exists("pod"))  usage(true);

    if (nonopt.size()) throw Err() << "unexpected value: " << nonopt[0];

    bool wgs = O.get("wgs", false);
    bool ex  = O.get("ext", false);
    bool cnt = O.get("center", false);

    O.check_conflict({"cover", "shift"});

    // get map name if needed
    std::string name; // given map name
    dRect range_n; // calculated coordinate range for the name
    if (O.exists("name")){
      name = O.get("name", "");
      nom_scale_t sc;
      range_n = nom_to_range(name, sc, ex);

      iPoint sh = O.get("shift", iPoint());
      if (sh!=iPoint()){
        cout << nom_shift(name, sh, ex) << "\n";
        return 0;
      }

      if (O.exists("scale")){
        nom_scale_t scn = str_to_type<nom_scale_t>(O.get("scale", ""));
        dRect r = expand(nom_to_range(name, sc, ex), -0.001, -0.001);
        set<string> names = range_to_nomlist(r, scn, ex);
        for (auto const & n:names) cout << n << "\n";
        return 0;
      }

      if (!O.exists("cover")){
        if (wgs){
          ConvGeo cnv("SU_LL", "WGS");
          range_n = cnv.frw_acc(range_n, 1e-7);
        }
        if (cnt) cout << range_n.cnt() << "\n";
        else     cout << range_n << "\n";
        return 0;
      }

    }


    // get maps touching a given figure
    if (O.exists("cover")){

      dMultiLine ml = figure_geo_line(O.get("cover",""));

      // convert WGS -> Pulkovo
      if (wgs){
        ConvGeo cnv("SU_LL", "WGS");
        ml = cnv.bck_pts(ml);
      }
      dRect range = ml.bbox();
      if (range.is_empty()) throw Err()
        << "wrong coordinate range: " << O.get("cover","");

      nom_scale_t sc;
      if (O.exists("name")){
        // calculate scale
        auto r = nom_to_range(O.get("name"), sc, ex);

        if (O.exists("cover_ratio")){
          dMultiLine crop = rect_crop_multi(r, ml, true);
          double a = 0.0;
          for (auto i=crop.begin(); i!=crop.end(); ++i){
            double da = fabs(i->area());
            if (i!=crop.begin() && check_hole(*crop.begin(), *i)) da=-da;
            a+=da;
          }
          std::cout << a / r.w / r.h << "\n";
          return 0;
        }

        else {
          return !rect_in_polygon(r, ml);
        }
      }

      if (!O.exists("scale")) throw Err() << "scale is not set";
      sc = str_to_type<nom_scale_t>(O.get("scale", ""));

      // calculate all maps in the range
      auto nn = range_to_nomlist(range, sc, ex);
      for (const auto & n: nn) {
        if (!rect_in_polygon(nom_to_range(n, sc, ex), ml)) continue;
        cout << n << "\n";
      }
      return 0;
    }

    throw Err() << "--name, --range, or --cover option expected";

  }
  catch (Err & e) {
    if (e.str()!="") cerr << "Error: " << e.str() << "\n";
    return 1;
  }
  return 0;
}

