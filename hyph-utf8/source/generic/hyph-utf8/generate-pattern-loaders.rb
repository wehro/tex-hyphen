#!/usr/bin/env ruby

# this file auto-generates loaders for hyphenation patterns - to be improved

load 'languages.rb'

$package_name="hyph-utf8"


# TODO - make this a bit less hard-coded
$path_tex_generic=File.expand_path("../../../tex/generic")
$path_loadhyph="#{$path_tex_generic}/#{$package_name}/loadhyph"

# TODO: should be singleton
languages = Languages.new.list

#text_if_native_utf = "\input pattern-loader.tex\n\\ifNativeUtfEightPatterns"

languages.each do |language|

string_enc = (language.encoding == nil) ? "" : language.encoding.upcase + " "

################
# Header texts #
################

# a message about auto-generation
# TODO: write a more comprehensive one
text_header =
"% filename: loadhyph-#{language.code}.tex
% language: #{language.name}
%
% Loader for hyphenation patterns, generated by
%     source/generic/hyph-utf8/generate-pattern-loaders.rb
% See also http://tug.org/tex-hyphen
%
% Copyright 2008-2010 TeX Users Group.
% You may freely use, modify and/or distribute this file.
% (But consider adapting the scripts if you need modifications.)
%
% Once it turns out that more than a simple definition is needed,
% these lines may be moved to a separate file.
%"

text_if_native_utf =
'% Test for pTeX
\\ifx\\kanjiskip\\undefined
% Test for native UTF-8 (which gets only a single argument)
% That\'s Tau (as in Taco or ΤΕΧ, Tau-Epsilon-Chi), a 2-byte UTF-8 character
\\def\\testengine#1#2!{\\def\\secondarg{#2}}\\testengine Τ!\\relax
\\ifx\\secondarg\\empty'

comment_engine_utf8 = "% Unicode-aware engine (such as XeTeX or LuaTeX) only sees a single (2-byte) argument"
comment_engine_8bit = "% 8-bit engine (such as TeX or pdfTeX)"
comment_engine_ptex = "% pTeX"

text_engine_ascii   = ["% ASCII patterns - no additional support is needed",
                       "\\message{ASCII #{language.message}}",
                       "\\input hyph-#{language.code}.tex"]
text_engine_utf8    = ["    #{comment_engine_utf8}",
                       "    \\message{UTF-8 #{language.message}}"]
text_engine_8bit    = ["    #{comment_engine_8bit}",
                       "    \\message{#{string_enc}#{language.message}}"]
text_engine_ptex    = ["    #{comment_engine_ptex}",
                       "    \\message{#{string_enc}#{language.message}}"]
text_engine_8bit_no = ["    #{comment_engine_8bit}",
                       "    \\message{No #{language.message} - only for Unicode engines}",
                       "    \\input zerohyph.tex"]
text_engine_ptex_no = ["    #{comment_engine_ptex}",
                       "    \\message{No #{language.message} - only for Unicode engines}",
                       "    \\input zerohyph.tex"]
text_patterns       =  "    \\input hyph-#{language.code}.tex"
text_patterns_ptex  =  "    \\input phyph-#{language.code}.tex"
text_patterns_old   =  "    \\input #{language.filename_old_patterns}"
text_patterns_conv  =  "    \\input conv-utf8-#{language.encoding}.tex"

###########
# lccodes #
###########

lccodes_common = []
if language.code == 'it' or language.code == 'fr' or language.code == 'uk' or language.code == 'zh-latn' then
	lccodes_common.push("\\lccode`\\'=`\\'")
end
if language.code == 'pt' or language.code == 'tk' or language.code == 'ru' or language.code == 'uk' then
	lccodes_common.push("\\lccode`\\-=`\\-")
end

	if language.use_new_loader then
		if language.code == 'sh-latn' then
			filename = "#{$path_loadhyph}/loadhyph-sr-latn.tex"
		else
			filename = "#{$path_loadhyph}/loadhyph-#{language.code}.tex"
		end
		puts "generating '#{filename}'"

		File.open(filename, "w") do |file|
			file.puts text_header
			file.puts('\begingroup')

			if lccodes_common.length > 0 then
				file.puts lccodes_common.join("\n")
			end

########################################
# GROUP nr. 1 - ONLY USABLE WITH UTF-8 #
########################################
			# some special cases firs
			#
			# some languages (sanskrit) are useless in 8-bit engines; we only want to load them for UTF engines
			# TODO - maybe consider doing something similar for ibycus
			if ['sa','as','bn','gu','hi','hy','kn','lo','ml','mr','or','pa','ta','te'].include?(language.code) then
				file.puts(text_if_native_utf)
				file.puts(text_engine_utf8)
				# lccodes
				if language.code != 'lo' then
					file.puts('    % Set \lccode for ZWNJ and ZWJ.')
					file.puts('    \lccode"200C="200C')
					file.puts('    \lccode"200D="200D')
					if language.code == 'sa' then
						file.puts('    % Set \lccode for KANNADA SIGN JIHVAMULIYA and KANNADA SIGN UPADHMANIYA.')
						file.puts('    \lccode"0CF1="0CF1')
						file.puts('    \lccode"0CF2="0CF2')
					end
				end
				file.puts(text_patterns)
				file.puts('\else')
				file.puts(text_engine_8bit_no)
				file.puts('\fi\else')
				file.puts(text_engine_ptex_no)
				file.puts('\fi')

#######################
# GROUP nr. 2 - ASCII #
#######################
			# for ASCII encoding, we don't load any special support files, but simply load everything
			elsif language.encoding == "ascii" then
				file.puts(text_engine_ascii)
####################################
# GROUP nr. 3 - different patterns #
####################################
			# when lanugage uses old patterns for 8-bit engines, load two different patterns rather than using the converter
			elsif language.use_old_patterns then
				file.puts(text_if_native_utf)
				file.puts(text_engine_utf8)
				# some catcodes for XeTeX
				if language.code == 'grc' or language.code.slice(0,2) == 'el' then
					file.puts("    \\lccode`'=`'\\lccode`’=`’\\lccode`ʼ=`ʼ\\lccode`᾽=`᾽\\lccode`᾿=`᾿")
				end
				file.puts(text_patterns)
				# russian and ukrainian exceptions - hacks with dashes
				if language.code == 'ru' or language.code == 'uk' then
					file.puts('    % Additional patterns with hyphen/dash: a hack to prevent breaking after hyphen, but not before.')
					file.puts("    \\input exhyph-#{language.code}.tex")
				end
				file.puts('\else')
				file.puts(text_engine_8bit)
				# explain why we are still using the old patterns
				if language.use_old_patterns_comment != nil then
					file.puts("    % #{language.use_old_patterns_comment}")
				else
					puts "Missing comment for #{language.name}"
					file.puts('    % we still load old patterns for 8-bit TeX')
				end
				file.puts(text_patterns_old)
				file.puts('\fi\else')
				file.puts(text_engine_ptex)
				# greek, coptic
				if language.encoding == nil then
					file.puts(text_patterns_old)
				else
					file.puts(text_patterns_ptex)
				end
				file.puts('\fi')
#########################
# GROUP nr. 4 - regular #
#########################
			else
				file.puts(text_if_native_utf)
				file.puts(text_engine_utf8)
				file.puts(text_patterns)
				file.puts('\else')
				file.puts(text_engine_8bit)
				# a hack for OT1 encoding in three languages
				if language.code == 'da' or language.code == 'fr' then
					file.puts("    % A hack to support both EC and OT1 encoding in 8-bit engines.")
					file.puts("    % Kept for backward compatibility only, though we would prefer to drop it.")
					file.puts("    % OT1 encoding is close-to-useless for proper hyphenation.")
					file.puts("    \\input spechyph-ot1-#{language.code}.tex")
				end
				file.puts(text_patterns_conv)
				file.puts(text_patterns)
				file.puts('\fi\else')
				file.puts(text_engine_ptex)
				file.puts(text_patterns_ptex)
				file.puts('\fi')
			end
#######
# end #
#######
			file.puts('\endgroup')
		end
	end
end


