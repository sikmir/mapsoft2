#ifndef ICONV_H
#define ICONV_H

#include <string>
#include <memory>

///\addtogroup libmapsoft
///@{

/// Wrapper for libiconv.
class IConv{

    class Impl;
    std::unique_ptr<Impl> impl;

  public:

    /// Constructors
    IConv();
    IConv(const char *from, const char *to);

    /// Destructor
    ~IConv();

    /// convert
    std::string operator()(const std::string & s) const;
};

///@}
#endif
