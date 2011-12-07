#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <aalib.h>

static void boot_setup_const(void)
{
    HV *stash = gv_stashpv("Text::AAlib", 1);

    /* enum aa_dithering_mode */
    newCONSTSUB(stash, "AA_NONE", newSViv(AA_NONE));
    newCONSTSUB(stash, "AA_ERRORDISTRIB", newSViv(AA_ERRORDISTRIB));
    newCONSTSUB(stash, "AA_FLOYD_S", newSViv(AA_FLOYD_S));
    newCONSTSUB(stash, "AA_DITHERTYPES", newSViv(AA_DITHERTYPES));
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
xs_putpixel(SV *self, SV *x, SV *y, SV *color)
CODE:
{
    aa_context *context;

    context = INT2PTR(aa_context*, SvIV(SvRV(self)));
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
xs_render(struct aa_context *context, HV *renderparams, SV *x1, SV *y1, SV *x2, SV *y2)
CODE:
{
    struct aa_renderparams ar;
    IV _x2, _y2;

    _x2 = SvOK(x2) ? SvIV(x2) : aa_scrwidth(context);
    _y2 = SvOK(y2) ? SvIV(y2) : aa_scrheight(context);

    ar.bright    = SvIV(*hv_fetchs(renderparams, "bright", 0));
    ar.contrast  = SvIV(*hv_fetchs(renderparams, "contrast", 0));
    ar.gamma     = SvNV(*hv_fetchs(renderparams, "gamma", 0));
    ar.dither    = SvIV(*hv_fetchs(renderparams, "dither", 0));
    ar.inversion = SvIV(*hv_fetchs(renderparams, "inversion", 0));
    ar.randomval = SvIV(*hv_fetchs(renderparams, "randomval", 0));

    aa_render(context, &ar, SvIV(x1), SvIV(y1), _x2, _y2);
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
