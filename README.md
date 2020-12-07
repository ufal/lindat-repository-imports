# What?
A set of scripts/transformations to convert supplied metadata into a format suitable by https://github.com/ufal/clarin-dspace

Currently contains conversions for:
 - NFA
   - Mnichovská dohoda
   
## Prerequisites
java, xmllint, saxon


## Running
First set the following variables, or run with defaults

 - `CP`, path to `SAXON*.jar`, default: `/mnt/c/Users/ko_ok/.m2/repository/net/sf/saxon/Saxon-HE/9.9.1-6/Saxon-HE-9.9.1-6.jar`
 - `DATADIR`, path to DATA, default: `project root/NFA`, expecting directories per ZF (eg. ZF_1 with metdata in .xml and shots as .mov)
 - `PREFIX`, handle prefix under which the newly created items will be registered, default dummy 123456789, it's using ZF ID in the handle, can't be left on DSpace alone
 - `CONTACT_PERSON`, a contact person who can provide further details about the item, default dummy `Tomáš@@Fuk@@fuk@example.com@@Example ltd.`