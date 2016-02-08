class Badge < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  A_NONE_SVG          = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"126\" height=\"20\"><linearGradient id=\"b\" x2=\"0\" y2=\"100%\"><stop offset=\"0\" stop-color=\"#bbb\" stop-opacity=\".1\"/><stop offset=\"1\" stop-opacity=\".1\"/></linearGradient><mask id=\"a\"><rect width=\"126\" height=\"20\" rx=\"3\" fill=\"#fff\"/></mask><g mask=\"url(#a)\"><path fill=\"#555\" d=\"M0 0h88v20H0z\"/><path fill=\"#97CA00\" d=\"M88 0h38v20H88z\"/><path fill=\"url(#b)\" d=\"M0 0h126v20H0z\"/></g><g fill=\"#fff\" text-anchor=\"middle\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\"><text x=\"44\" y=\"15\" fill=\"#010101\" fill-opacity=\".3\">dependencies</text><text x=\"44\" y=\"14\">dependencies</text><text x=\"106\" y=\"15\" fill=\"#010101\" fill-opacity=\".3\">none</text><text x=\"106\" y=\"14\">none</text></g></svg>"
  A_NONE_SVG_FLAT     = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"126\" height=\"20\"><g shape-rendering=\"crispEdges\"><path fill=\"#555\" d=\"M0 0h88v20H0z\"/><path fill=\"#97CA00\" d=\"M88 0h38v20H88z\"/></g><g fill=\"#fff\" text-anchor=\"middle\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\"><text x=\"45\" y=\"14\">dependencies</text><text x=\"106\" y=\"14\">none</text></g></svg>"

  A_UPTODATE_SVG      = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"156\" height=\"20\"><linearGradient id=\"b\" x2=\"0\" y2=\"100%\"><stop offset=\"0\" stop-color=\"#bbb\" stop-opacity=\".1\"/><stop offset=\"1\" stop-opacity=\".1\"/></linearGradient><mask id=\"a\"><rect width=\"156\" height=\"20\" rx=\"3\" fill=\"#fff\"/></mask><g mask=\"url(#a)\"><path fill=\"#555\" d=\"M0 0h88v20H0z\"/><path fill=\"#97CA00\" d=\"M88 0h68v20H88z\"/><path fill=\"url(#b)\" d=\"M0 0h156v20H0z\"/></g><g fill=\"#fff\" text-anchor=\"middle\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\"><text x=\"44\" y=\"15\" fill=\"#010101\" fill-opacity=\".3\">dependencies</text><text x=\"44\" y=\"14\">dependencies</text><text x=\"121\" y=\"15\" fill=\"#010101\" fill-opacity=\".3\">up to date</text><text x=\"121\" y=\"14\">up to date</text></g></svg>"
  A_UPTODATE_SVG_FLAT = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"156\" height=\"20\"><g shape-rendering=\"crispEdges\"><path fill=\"#555\" d=\"M0 0h88v20H0z\"/><path fill=\"#4c1\" d=\"M88 0h68v20H88z\"/></g><g fill=\"#fff\" text-anchor=\"middle\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\"><text x=\"45\" y=\"14\">dependencies</text><text x=\"121\" y=\"14\">up to date</text></g></svg>"

  A_OUTOFDATE_SVG      = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"160\" height=\"20\"><linearGradient id=\"b\" x2=\"0\" y2=\"100%\"><stop offset=\"0\" stop-color=\"#bbb\" stop-opacity=\".1\"/><stop offset=\"1\" stop-opacity=\".1\"/></linearGradient><mask id=\"a\"><rect width=\"160\" height=\"20\" rx=\"3\" fill=\"#fff\"/></mask><g mask=\"url(#a)\"><path fill=\"#555\" d=\"M0 0h88v20H0z\"/><path fill=\"#dfb317\" d=\"M88 0h72v20H88z\"/><path fill=\"url(#b)\" d=\"M0 0h160v20H0z\"/></g><g fill=\"#fff\" text-anchor=\"middle\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\"><text x=\"44\" y=\"15\" fill=\"#010101\" fill-opacity=\".3\">dependencies</text><text x=\"44\" y=\"14\">dependencies</text><text x=\"123\" y=\"15\" fill=\"#010101\" fill-opacity=\".3\">out of date</text><text x=\"123\" y=\"14\">out of date</text></g></svg>"
  A_OUTOFDATE_SVG_FLAT = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"166\" height=\"20\"><g shape-rendering=\"crispEdges\"><path fill=\"#555\" d=\"M0 0h88v20H0z\"/><path fill=\"#dfb317\" d=\"M88 0h78v20H88z\"/></g><g fill=\"#fff\" text-anchor=\"middle\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\"><text x=\"45\" y=\"14\">dependencies</text><text x=\"126\" y=\"14\">out_of_date</text></g></svg>"

  A_UPDATE_SVG         = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"146\" height=\"20\"><linearGradient id=\"b\" x2=\"0\" y2=\"100%\"><stop offset=\"0\" stop-color=\"#bbb\" stop-opacity=\".1\"/><stop offset=\"1\" stop-opacity=\".1\"/></linearGradient><mask id=\"a\"><rect width=\"146\" height=\"20\" rx=\"3\" fill=\"#fff\"/></mask><g mask=\"url(#a)\"><path fill=\"#555\" d=\"M0 0h88v20H0z\"/><path fill=\"#e05d44\" d=\"M88 0h58v20H88z\"/><path fill=\"url(#b)\" d=\"M0 0h146v20H0z\"/></g><g fill=\"#fff\" text-anchor=\"middle\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\"><text x=\"44\" y=\"15\" fill=\"#010101\" fill-opacity=\".3\">dependencies</text><text x=\"44\" y=\"14\">dependencies</text><text x=\"116\" y=\"15\" fill=\"#010101\" fill-opacity=\".3\">insecure</text><text x=\"116\" y=\"14\">insecure</text></g></svg>"
  A_UPDATE_SVG_FLAT    = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"146\" height=\"20\"><g shape-rendering=\"crispEdges\"><path fill=\"#555\" d=\"M0 0h88v20H0z\"/><path fill=\"#e05d44\" d=\"M88 0h58v20H88z\"/></g><g fill=\"#fff\" text-anchor=\"middle\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\"><text x=\"45\" y=\"14\">dependencies</text><text x=\"116\" y=\"14\">insecure</text></g></svg>"

  A_UNKNOWN_SVG   = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"149\" height=\"20\"><linearGradient id=\"b\" x2=\"0\" y2=\"100%\"><stop offset=\"0\" stop-color=\"#bbb\" stop-opacity=\".1\"/><stop offset=\"1\" stop-opacity=\".1\"/></linearGradient><mask id=\"a\"><rect width=\"149\" height=\"20\" rx=\"3\" fill=\"#fff\"/></mask><g mask=\"url(#a)\"><path fill=\"#555\" d=\"M0 0h88v20H0z\"/><path fill=\"#9f9f9f\" d=\"M88 0h61v20H88z\"/><path fill=\"url(#b)\" d=\"M0 0h149v20H0z\"/></g><g fill=\"#fff\" text-anchor=\"middle\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\"><text x=\"44\" y=\"15\" fill=\"#010101\" fill-opacity=\".3\">dependencies</text><text x=\"44\" y=\"14\">dependencies</text><text x=\"117.5\" y=\"15\" fill=\"#010101\" fill-opacity=\".3\">unknown</text><text x=\"117.5\" y=\"14\">unknown</text></g></svg>"

  A_REF_0_SVG   = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"88\" height=\"20\"><linearGradient id=\"b\" x2=\"0\" y2=\"100%\"><stop offset=\"0\" stop-color=\"#bbb\" stop-opacity=\".1\"/><stop offset=\"1\" stop-opacity=\".1\"/></linearGradient><mask id=\"a\"><rect width=\"88\" height=\"20\" rx=\"3\" fill=\"#fff\"/></mask><g mask=\"url(#a)\"><path fill=\"#555\" d=\"M0 0h71v20H0z\"/><path fill=\"#e05d44\" d=\"M71 0h17v20H71z\"/><path fill=\"url(#b)\" d=\"M0 0h88v20H0z\"/></g><g fill=\"#fff\" text-anchor=\"middle\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\"><text x=\"35.5\" y=\"15\" fill=\"#010101\" fill-opacity=\".3\">references</text><text x=\"35.5\" y=\"14\">references</text><text x=\"78.5\" y=\"15\" fill=\"#010101\" fill-opacity=\".3\">0</text><text x=\"78.5\" y=\"14\">0</text></g></svg>"
  A_REF_TEMPLATE_SVG = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"123\" height=\"20\"><linearGradient id=\"b\" x2=\"0\" y2=\"100%\"><stop offset=\"0\" stop-color=\"#bbb\" stop-opacity=\".1\"/><stop offset=\"1\" stop-opacity=\".1\"/></linearGradient><mask id=\"a\"><rect width=\"123\" height=\"20\" rx=\"3\" fill=\"#fff\"/></mask><g mask=\"url(#a)\"><path fill=\"#555\" d=\"M0 0h71v20H0z\"/><path fill=\"#97CA00\" d=\"M71 0h52v20H71z\"/><path fill=\"url(#b)\" d=\"M0 0h123v20H0z\"/></g><g fill=\"#fff\" text-anchor=\"middle\" font-family=\"DejaVu Sans,Verdana,Geneva,sans-serif\" font-size=\"11\"><text x=\"35.5\" y=\"15\" fill=\"#010101\" fill-opacity=\".3\">references</text><text x=\"35.5\" y=\"14\">references</text><text x=\"96\" y=\"15\" fill=\"#010101\" fill-opacity=\".3\">TMP</text><text x=\"96\" y=\"14\">TMP</text></g></svg>"

  A_UP_TO_DATE  = 'up_to_date'
  A_OUT_OF_DATE = 'out_of_date'
  A_UPDATE      = 'insecure!'
  A_NONE        = 'none'
  A_UNKNOWN     = 'unknown'
  A_REF_0       = '0'

  A_SOURCE_PROJECT = 'project'
  A_SOURCE_PRODUCT = 'product'

  A_TYPE_DEPENDENCY = 'dependency'
  A_TYPE_REFERENCE  = 'reference'

  # project_id or 'lang:::prod_key:::version' or 'lang:::prod_key:::version:::type'
  field :key     , type: String

  # up-to-date or out-of-date
  field :status  , type: String

  # 'dependency' or 'reference'
  field :badge_type, type: String

  # 'project' or 'product'
  field :badge_source, type: String

  # The actual svg xml code
  field :svg     , type: String

  # nil or flat
  field :badge_style, type: String

  index({ key: 1 }, { name: "key_index", background: true, unique: true, drop_dups: true })

end
