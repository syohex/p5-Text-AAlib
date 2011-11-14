#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <aalib.h>

MODULE = Text::AAlib    PACKAGE = Text::AAlib

void
_init(SV *filename, SV *width, SV *height)
CODE:
{
    aa_context *context;
    aa_savedata save_data;
    struct aa_hardware_params param;

    save_data.name   = SvPV_nolen(filename);
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

    ST(0) = sv_2mortal( newSViv(PTR2IV(context)) );
    XSRETURN(1);
}

void
_putpixel(SV *self, SV *x, SV *y, SV *color)
CODE:
{
    aa_context *context;

    context = INT2PTR(aa_context*, SvIV(SvRV(self)));
    aa_putpixel(context, SvIV(x), SvIV(y), SvIV(color));
}

void
_fastrender(SV *self, SV *x1, SV *y1, SV *x2, SV *y2)
CODE:
{
    aa_context *context;
    IV _x2, _y2;
    context = INT2PTR(aa_context*, SvIV(SvRV(self)));

    _x2 = SvOK(x2) ? SvIV(x2) : aa_scrwidth(context);
    _y2 = SvOK(y2) ? SvIV(y2) : aa_scrheight(context);

    aa_fastrender(context, SvIV(x1), SvIV(y1), _x2, _y2);
}

void
_flush(SV *self)
CODE:
{
    aa_context *context;
    context = INT2PTR(aa_context*, SvIV(SvRV(self)));

    aa_flush(context);
}

void
_close(SV *self)
CODE:
{
    aa_context *context;

    context = INT2PTR(aa_context*, SvIV(SvRV(self)));
    aa_close(context);
}
