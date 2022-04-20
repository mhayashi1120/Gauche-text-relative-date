/*
 * gauche_text_relative_date.c
 */

#include "gauche_text_relative_date.h"

/*
 * The following function is a dummy one; replace it for
 * your C function definitions.
 */

ScmObj test_gauche_text_relative_date(void)
{
    return SCM_MAKE_STR("gauche_text_relative_date is working");
}

/*
 * Module initialization function.
 */
extern void Scm_Init_gauche_text_relative_datelib(ScmModule*);

void Scm_Init_gauche_text_relative_date(void)
{
    ScmModule *mod;

    /* Register this DSO to Gauche */
    SCM_INIT_EXTENSION(gauche_text_relative_date);

    /* Create the module if it doesn't exist yet. */
    mod = SCM_MODULE(SCM_FIND_MODULE("gauche_text_relative_date", TRUE));

    /* Register stub-generated procedures */
    Scm_Init_gauche_text_relative_datelib(mod);
}
