# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
# muniversal-1.0.tcl
#
# $Id$
#
# Copyright (c) 2009 The MacPorts Project,
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of Apple Computer, Inc. nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# User variables:
#         merger_configure_env: associative array of configure.env variables
#             merger_build_env: assoicative array of build.env variables
#                  merger_host: associative array of host values
#        merger_configure_args: associative array of configure.args
#    merger_configure_cppflags: associative array of configure.cppflags
#      merger_configure_cflags: associative array of configure.cflags
#    merger_configure_cxxflags: associative array of configure.cxxflags
#     merger_configure_ldflags: associative array of configure.ldflags
#             merger_dont_diff: list of file names for which diff will not work

if { ! [info exists universal_archs_supported] } {
    set universal_archs_supported  ${universal_archs}
}

variant universal {
    global universal_archs_to_use

    eval configure.args-append      ${configure.universal_args}
    eval configure.cflags-append    ${configure.universal_cflags}
    eval configure.cxxflags-append  ${configure.universal_cxxflags}
    eval configure.ldflags-append   ${configure.universal_ldflags}
    eval configure.cppflags-append  ${configure.universal_cppflags}

    foreach arch ${universal_archs} {
        configure.cflags-delete    -arch ${arch}
        configure.cxxflags-delete  -arch ${arch}
        configure.ldflags-delete   -arch ${arch}
    }

    # set universal_archs_to_use as the intersection of universal_archs and universal_archs_supported
    set universal_archs_to_use {}
    foreach arch ${universal_archs} {
        set arch_ok no
        foreach archt ${universal_archs_supported} {
            if { ${arch}==${archt} } {
                set arch_ok yes
            }
        }
        if { ${arch_ok}=="yes" } {
            lappend universal_archs_to_use ${arch}
        }
    }

    configure {
        foreach arch ${universal_archs_to_use} {
            ui_msg "$UI_PREFIX [format [msgcat::mc "Configuring %1\$s for architecture %2\$s"] [option portname] ${arch}]"

            copy ${worksrcpath} ${workpath}/${arch}

            set archf [muniversal_get_arch_flag ${arch}]
            configure.cflags-append    ${archf}
            configure.cxxflags-append  ${archf}
            configure.ldflags-append   ${archf}

            if { [info exists merger_configure_env(${arch})] } {
                configure.env-append  $merger_configure_env(${arch})
            }
            if { [info exists merger_configure_cppflags(${arch})] } {
                configure.cflags-append  $merger_configure_cppflags(${arch})
            }
            if { [info exists merger_configure_cflags(${arch})] } {
                configure.cflags-append  $merger_configure_cflags(${arch})
            }
            if { [info exists merger_configure_cxxflags(${arch})] } {
                configure.cflags-append  $merger_configure_cxxflags(${arch})
            }
            if { [info exists merger_configure_ldflags(${arch})] } {
                configure.cflags-append  $merger_configure_ldflags(${arch})
            }

            # Don't set the --host unless we have to.
            set host ""
            if { ${os.arch}=="i386" && (${arch}=="ppc" || ${arch}=="ppc64") } {
                if { [info exists merger_host(${arch})] } {
                    if { $merger_host(${arch}) != "" } {
                        set host  --host=$merger_host(${arch})
                    }
                } else {
                    if { ${arch}=="ppc" } {
                        set host --host=powerpc-apple-darwin
                    } else {
                        set host --host=powerpc64-apple-darwin
                    }
                }
            } elseif { ${os.arch}=="powerpc" && (${arch}=="i386" || ${arch}=="x86_64") } {
                if { [info exists merger_host(${arch})] } {
                    if { $merger_host(${arch}) != "" } {
                        set host  --host=$merger_host(${arch})
                    }
                } else {
                    if { ${arch}=="i386" } {
                        set host --host=i386-apple-darwin
                    } else {
                        set host --host=x86_64-apple-darwin
                    }
                }
            }
            configure.args-append  ${host}

            if { [info exists merger_configure_args(${arch})] } {
                configure.args-append  $merger_configure_args(${arch})
            }

            set configure_cc_save ${configure.cc}
            set configure_cxx_save ${configure.cxx}
            configure.cc   ${configure.cc}  ${archf}
            configure.cxx  ${configure.cxx} ${archf}

            set worksrcpathSave  ${worksrcpath}
            set worksrcpath  ${workpath}/${arch}

            configure_main

            # Undo changes to the configure related variables
            set worksrcpath  ${worksrcpathSave}
            configure.cc   ${configure_cc_save}
            configure.cxx  ${configure_cxx_save}
            if { [info exists merger_configure_args(${arch})] } {
                configure.args-delete  $merger_configure_args(${arch})
            }
            configure.args-delete  ${host}
            if { [info exists merger_configure_ldflags(${arch})] } {
                configure.cflags-delete  $merger_configure_ldflags(${arch})
            }
            if { [info exists merger_configure_cxxflags(${arch})] } {
                configure.cflags-delete  $merger_configure_cxxflags(${arch})
            }
            if { [info exists merger_configure_cflags(${arch})] } {
                configure.cflags-delete  $merger_configure_cflags(${arch})
            }
            if { [info exists merger_configure_cppflags(${arch})] } {
                configure.cflags-delete  $merger_configure_cppflags(${arch})
            }
            if { [info exists merger_configure_env(${arch})] } {
                configure.env-delete  $merger_configure_env(${arch})
            }
            configure.ldflags-delete  ${archf}
            configure.cxxflags-delete ${archf}
            configure.cflags-delete ${archf}
        }
    }

    build {
        foreach arch ${universal_archs_to_use} {
            ui_msg "$UI_PREFIX [format [msgcat::mc "Building %1\$s for architecture %2\$s"] [option portname] ${arch}]"
            
            if { [info exists merger_build_env(${arch})] } {
                build.env-append  $merger_build_env(${arch})
            }
            build.dir  ${workpath}/${arch}
            build_main
            if { [info exists merger_build_env(${arch})] } {
                build.env-delete  $merger_build_env(${arch})
            }
        }
    }

    destroot {
        foreach arch ${universal_archs_to_use} {
            ui_msg "$UI_PREFIX [format [msgcat::mc "Staging %1\$s into destroot for architecture %2\$s"] [option portname] ${arch}]"
            copy ${destroot} ${workpath}/destroot-${arch}
            destroot.dir  ${workpath}/${arch}
            set destdirSave ${destroot.destdir}
            destroot.destdir  [string map "${destroot} ${workpath}/destroot-${arch}" ${destroot.destdir}]
            destroot_main
            destroot.destdir ${destdirSave} 
        }
        delete ${destroot}

        # Merge ${base1}/${prefixDir} and ${base2}/${prefixDir} into dir ${base}/${prefixDir}
        #        arch1, arch2: names to prepend to files if a diff merge of two files is forbiddend by merger_dont_diff
        #    merger_dont_diff: list of files for which /usr/bin/diff ${diffFormat} will not merge correctly
        #          diffFormat: format used by diff to merge two text files
        proc merge2Dir {base1 base2 base prefixDir arch1 arch2 merger_dont_diff diffFormat} {
            set dir1  ${base1}/${prefixDir}
            set dir2  ${base2}/${prefixDir}
            set dir   ${base}/${prefixDir}

            xinstall -d -m 0755 ${dir}

            foreach fl [glob -directory ${dir2} -tails -nocomplain *] {
                if { ![file exists ${dir1}/${fl}] } {
                    # File only exists in ${dir1}
                    ui_debug "universal: merge: ${prefixDir}/${fl} only exists in ${base2}"
                    copy ${dir2}/${fl} ${dir}
                }
            }
            foreach fl [glob -directory ${dir1} -tails -nocomplain *] {
                if { ![file exists ${dir2}/${fl}] } {
                    # File only exists in ${dir2}
                    ui_debug "universal: merge: ${prefixDir}/${fl} only exists in ${base1}"
                    copy ${dir1}/${fl} ${dir}
                } else {
                    # File exists in ${dir1} and ${dir2}
                    ui_debug "universal: merge: merging ${prefixDir}/${fl} from ${base1} and ${base2}"

                    # Ensure files are of same type
                    if { [file type ${dir1}/${fl}]!=[file type ${dir2}/${fl}] } {
                        error "${dir1}/${fl} and ${dir2}/${fl} are of different types"
                    }

                    if { [file type ${dir1}/${fl}]=="link" } {
                        # Files are links
                        ui_debug "universal: merge: ${prefixDir}/${fl} is a link"

                        # Ensure links don't point to different things
                        if { [file readlink ${dir1}/${fl}]==[file readlink ${dir2}/${fl}] } {
                            copy ${dir1}/${fl} ${dir}
                        } else {
                            error "${dir1}/${fl} and ${dir2}/${fl} point to different targets (can't merge them)"
                        }
                    } elseif { [file isdirectory ${dir1}/${fl}] } {
                        # Files are directories (but not links), so recursively call function
                        merge2Dir ${base1} ${base2} ${base} ${prefixDir}/${fl} ${arch1} ${arch2} ${merger_dont_diff} ${diffFormat}
                    } else {
                        # Files are neither directories nor links
                        if { ! [catch {system "/usr/bin/cmp ${dir1}/${fl} ${dir2}/${fl} && /bin/cp -v ${dir1}/${fl} ${dir}"}] } {
                            # Files are byte by byte the same
                            ui_debug "universal: merge: ${prefixDir}/${fl} is identical in ${base1} and ${base2}"
                        } else {
                            # Actually try to merge the files
                            # First try lipo
                            if { ! [catch {system "/usr/bin/lipo -create ${dir1}/${fl} ${dir2}/${fl} -output ${dir}/${fl}"}] } {
                                # lipo worked
                                ui_debug "universal: merge: lipo created ${prefixDir}/${fl}"
                            } else {
                                # lipo has failed, so assume they are text files to be merged
                                set dontdiff no
                                foreach dont ${merger_dont_diff} {
                                    if { ${dont}=="${prefixDir}/${fl}" } {
                                        set dontdiff yes
                                    }
                                }
                                if { ${dontdiff}==yes } {
                                    # user has specified that diff does not work
                                    # attempt to give each file a unique name and create a new file which includes one of the original depending on the arch

                                    set fh [open ${dir}/${arch1}-${fl} w 0644]
                                    puts ${fh} "#include \"${arch1}-${fl}\""
                                    close ${fh}

                                    set fh [open ${dir}/${arch2}-${fl} w 0644]
                                    puts ${fh} "#include \"${arch2}-${fl}\""
                                    close ${fh}

                                    ui_debug "universal: merge: created ${prefixDir}/${fl} to include ${prefixDir}/${arch1}-${fl} ${prefixDir}/${arch1}-${fl}"

                                    system "/usr/bin/diff -d ${diffFormat} ${dir}/${arch1}-${fl} ${dir}/${arch2}-${fl} > ${dir}/${fl}; test \$? -le 1"

                                    copy -force ${dir1}/${fl} ${dir}/${arch1}-${fl}
                                    copy -force ${dir2}/${fl} ${dir}/${arch2}-${fl}
                                } elseif { ! [catch {system "/usr/bin/diff -dw ${diffFormat} ${dir1}/${fl} ${dir2}/${fl} > ${dir}/${fl}; test \$? -le 1"} ] } {
                                    # diff worked
                                    ui_debug "universal: merge: used diff to create ${prefixDir}/${fl}"
                                } else {
                                    # File created by diff is invalid
                                    delete ${dir}/${fl}

                                    # nothing has worked so far.
                                    switch -glob ${fl} {
                                        *.jar {
                                            # jar files can be different becasue of timestamp
                                            ui_debug "universal: merge: ${prefixDir}/${fl} is different in ${base1} and ${base2}; assume timestamp difference"
                                            copy ${dir1}/${fl} ${dir}
                                        }
                                        default {
                                            error "Can not create ${prefixDir}/${fl} from ${base1} and ${base2}"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        # /usr/bin/diff can merge two C/C++ files
        # See http://www.gnu.org/software/diffutils/manual/html_mono/diff.html#If-then-else
        # See http://www.gnu.org/software/diffutils/manual/html_mono/diff.html#Detailed%20If-then-else
        set diffFormatProc {--old-group-format='#if (defined(__ppc__) || defined(__ppc64__))
 %<#endif /* __ppc__ || __ppc64__ */
' \
--new-group-format='#if defined (__i386__) || defined(__x86_64__)
%>#endif /* __i386__ || __x86_64__ */
' \
--unchanged-group-format='%=' \
--changed-group-format='#if (defined(__ppc__) || defined(__ppc64__))
%<#else /* ! __ppc__ && ! __ppc64__ */
%>#endif /* __ppc__ || __ppc64__ */
'}

        set diffFormatM "-D __LP64__"

        if { ![info exists merger_dont_diff] } {
            set merger_dont_diff {}
        }

        merge2Dir  ${workpath}/destroot-ppc      ${workpath}/destroot-ppc64 ${workpath}/destroot-powerpc  ""  ppc ppc64    ${merger_dont_diff}  ${diffFormatM}
        merge2Dir  ${workpath}/destroot-i386     ${workpath}/destroot-x86_64 ${workpath}/destroot-intel   ""  i386 x86_64  ${merger_dont_diff}  ${diffFormatM}
        merge2Dir  ${workpath}/destroot-powerpc  ${workpath}/destroot-intel ${workpath}/destroot          ""  powerpc x86  ${merger_dont_diff}  ${diffFormatProc}
    }

    test {
        foreach arch ${universal_archs_to_use} {
            # Rosetta does not translate G5 instructions
            # PowerPC systems can't translate Intel instructions
            if { (${os.arch}=="i386" && ${arch}!="ppc64") || (${os.arch}=="powerpc" && ${arch}!="i386" && ${arch}!="x86_64") } {
                ui_msg "$UI_PREFIX [format [msgcat::mc "Testing %1\$s for architecture %2\$s"] [option portname] ${arch}]"
                test.dir  ${workpath}/${arch}
                test_main
            }
        }
    }

    proc muniversal_get_arch_flag {arch} {
        global os.arch
        # Prefer -m to -arch
        set archf "-arch ${arch}"
        if { ${os.arch}=="i386" && ${arch}=="i386" } {
            set archf -m32
        } elseif { ${os.arch}=="i386" && ${arch}=="x86_64" } {
            set archf -m64
        } elseif { ${os.arch}=="powerpc" && ${arch}=="ppc" } {
            set archf -m32
        } elseif { ${os.arch}=="powerpc" && ${arch}=="ppc64" } {
            set archf -m64
        }
        return ${archf}
    }
}
