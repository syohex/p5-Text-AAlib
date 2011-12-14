#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <aalib.h>

struct xs_aa_info {
    aa_context *context;
    char *filename;
};

static void boot_setup_const(void)
{
    HV *stash = gv_stashpv("Text::AAlib", 1);

    /* enum aa_dithering_mode */
    newCONSTSUB(stash, "AA_NONE"         , newSViv(AA_NONE));
    newCONSTSUB(stash, "AA_ERRORDISTRIB" , newSViv(AA_ERRORDISTRIB));
    newCONSTSUB(stash, "AA_FLOYD_S"      , newSViv(AA_FLOYD_S));
    newCONSTSUB(stash, "AA_DITHERTYPES"  , newSViv(AA_DITHERTYPES));

    /* enum aa_attribute */
    newCONSTSUB(stash, "AA_NORMAL"   , newSViv(AA_NORMAL));
    newCONSTSUB(stash, "AA_BOLD"     , newSViv(AA_BOLD));
    newCONSTSUB(stash, "AA_DIM"      , newSViv(AA_DIM));
    newCONSTSUB(stash, "AA_BOLDFONT" , newSViv(AA_BOLDFONT));
    newCONSTSUB(stash, "AA_REVERSE"  , newSViv(AA_REVERSE));
}

MODULE = Text::AAlib    PACKAGE = Text::AAlib

PROTOTYPES: disable

BOOT:
    boot_setup_const();

void
xs_init(SV *filename, SV *width, SV *height)
CODE:
{
    aa_context *context;
    aa_savedata save_data;
    struct aa_hardware_params param;
    struct xs_aa_info *ai;

    Newx(ai, 1, struct xs_aa_info);
    if (ai == NULL) {
        croak("Can't allocate memory(struct xs_aa_info)");
    }

    Newx(ai->filename, SvLEN(filename), char);
    if (ai->filename == NULL) {
        croak("Can't allocate memory(file name)");
    }
    Copy(SvPV_nolen(filename), ai->filename, SvLEN(filename), char);

    save_data.name   = ai->filename;
    save_data.format = &aa_text_format;
    param = aa_defparams;

    if (SvOK(width)) {
        param.width  = SvIV(width);
    }
    if (SvOK(height)) {
        param.height  = SvIV(height);
    }

    context = aa_init(&save_d, &param, (const void*)&save_data);
    if (context == NULL) {
        croak("Error aa_init");
    }

    ai->context = context;
    ST(0) = sv_2mortal( newSViv(PTR2IV(ai)) );
    XSRETURN(1);
}

void
xs_putpixel(struct aa_context *context, SV *x, SV *y, SV *color)
CODE:
{
    aa_putpixel(context, SvIV(x), SvIV(y), SvIV(color));
}

void
xs_puts(struct aa_context *context, SV *x, SV *y, SV *attr, SV *str)
CODE:
{
    aa_puts(context, SvIV(x), SvIV(y), SvIV(attr), SvPV_nolen(str));
}

void
xs_fastrender(struct aa_context *context, SV *x1, SV *y1, SV *x2, SV *y2)
CODE:
{
    IV _x2, _y2;

    _x2 = SvOK(x2) ? SvIV(x2) : aa_scrwidth(context);
    _y2 = SvOK(y2) ? SvIV(y2) : aa_scrheight(context);

    aa_fastrender(context, SvIV(x1), SvIV(y1), _x2, _y2);
}

void
xs_render(struct aa_context *context, struct aa_renderparams ar, \
          SV *x1, SV *y1, SV *x2, SV *y2)
CODE:
{
    IV _x2, _y2;

    _x2 = SvOK(x2) ? SvIV(x2) : aa_scrwidth(context);
    _y2 = SvOK(y2) ? SvIV(y2) : aa_scrheight(context);

    aa_render(context, &ar, SvIV(x1), SvIV(y1), _x2, _y2);
}

void
xs_resize(struct aa_context *context)
CODE:
{
    aa_resize(context);
}

void
xs_flush(struct aa_context *context)
CODE:
{
    aa_flush(context);
}

void
xs_close(struct aa_context *context)
CODE:
{
    aa_close(context);
}

void
xs_DESTROY(SV *aa_info)
CODE:
{
    struct xs_aa_info *ai = INT2PTR(struct xs_aa_info*, SvIV(aa_info));
    Safefree(ai->filename);
    Safefree(ai);
}
