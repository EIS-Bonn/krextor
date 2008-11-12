<?xml version="1.0" encoding="UTF-8"?>

<!--
    *  Copyright (C) 2008
    *  Christoph Lange
    *  Jacobs University Bremen
    *
    *   Krextor is free software; you can redistribute it and/or
    * 	modify it under the terms of the GNU Lesser General Public
    * 	License as published by the Free Software Foundation; either
    * 	version 2 of the License, or (at your option) any later version.
    *
    * 	This program is distributed in the hope that it will be useful,
    * 	but WITHOUT ANY WARRANTY; without even the implied warranty of
    * 	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    * 	Lesser General Public License for more details.
    *
    * 	You should have received a copy of the GNU Lesser General Public
    * 	License along with this library; if not, write to the
    * 	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
    * 	Boston, MA 02111-1307, USA.
    * 
-->

<!DOCTYPE stylesheet [
    <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
]>

<!--
    This stylesheet extracts RDF from XHTML documents annotated with RDFa.
-->
<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" 
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    version="2.0">

    <import href="util/openmath/verb.xsl"/>
    
    <strip-space elements="*"/>

    <param name="autogenerate-fragment-uris" select="()"/>

    <function name="krextor:curie-to-uri">
	<param name="focus"/>
	<param name="curie"/>
	<choose>
	    <when test="$curie">
		<analyze-string select="$curie" regex="^(([^:]*):)?(.+)$">
		    <matching-substring>
			<variable name="no-prefix" select="not(matches(regex-group(1), ':$'))"/>
			<variable name="prefix" select="regex-group(2)"/>
			<variable name="localname" select="regex-group(3)"/>
			<variable name="resolved-uri" select="resolve-QName($curie, $focus)"/>
			<choose>
			    <when test="$no-prefix and
				$localname = (
				'alternate',
				'appendix',
				'bookmark',
				'cite',
				'chapter',
				'contents',
				'copyright',
				'first',
				'glossary',
				'help',
				'icon',
				'index',
				'last',
				'license',
				'meta',
				'next',
				'p3pv1',
				'prev',
				'role',
				'section',
				'stylesheet',
				'subsection',
				'start',
				'top',
				'up'
				)">
				<value-of select="concat('http://www.w3.org/1999/xhtml/vocab#', $localname)"/>
			    </when>
			    <otherwise>
				<value-of select="concat(namespace-uri-from-QName($resolved-uri), local-name-from-QName($resolved-uri))"/>
			    </otherwise>
			</choose>
		    </matching-substring>
		</analyze-string>
	    </when>
	    <otherwise>
		<sequence select="()"/>
	    </otherwise>
	</choose>
    </function>

    <function name="krextor:curies-to-uris">
	<param name="focus"/>
	<param name="curie"/>
	<choose>
	    <when test="matches($curie, ' ')">
		<sequence select="for $c in tokenize($curie, '\s+')
		    return krextor:curie-to-uri($focus, $c)"/>
	    </when>
	    <otherwise>
		<sequence select="krextor:curie-to-uri($focus, $curie)"/>
	    </otherwise>
	</choose>
    </function>

    <function name="krextor:safe-curie-to-uri">
	<param name="focus"/>
	<param name="safe-curie"/>
	<analyze-string select="$safe-curie" regex="^\[([^\]]+)\]$">
	    <matching-substring>
		<value-of select="krextor:curie-to-uri($focus, regex-group(1))"/>
	    </matching-substring>
	    <non-matching-substring>
		<value-of select="."/>
	    </non-matching-substring>
	</analyze-string>
    </function>

    <template match="/">
	<apply-imports>
	    <with-param name="krextor:base-uri" select="/html/head/base[1]/@href" tunnel="yes"/>
	</apply-imports>
    </template>

    <!-- FIXME restrict to those elements where @about is actually allowed -->
    <!-- TODO treat @src same as @about -->
    <template match="*[@about or @typeof]">
	<call-template name="krextor:create-resource">
	    <with-param name="subject" select="krextor:safe-curie-to-uri(., @about)"/>
	    <with-param name="blank-node" select="not(@about)"/>
	    <with-param name="type" select="krextor:curies-to-uris(., @typeof)"/>
	    <!-- FIXME actually, this is:
		@content, or ...
		@... (some other RDFa properties) -->
	    <with-param name="process-next" select="*"/>
	</call-template>
    </template>

    <template match="*[@property and not(@content|node())]">
	<call-template name="krextor:create-property">
	    <with-param name="property" select="krextor:curies-to-uris(., @property)"/>
	</call-template>
    </template>

    <template match="*[(@property and node()) or @content]">
	<variable name="object">
	    <choose>
		<when test="@content">
		    <value-of select="@content"/>
		</when>
		<when test="*">
		    <apply-templates select="*" mode="verb"/>
		</when>
		<otherwise>
		    <value-of select="text()"/>
		</otherwise>
	    </choose>
	</variable>
	<call-template name="krextor:add-literal-property">
	    <!-- this function returns NIL if there is no @property attribute.
	         Then, add-literal-property completes an incomplete triple -->
	    <with-param name="property" select="krextor:curies-to-uris(., @property)"/>
	    <with-param name="object" select="$object"/>
	    <with-param name="object-language" select="@xml:lang"/>
	    <!-- TODO test with datatype="" -->
	    <with-param name="object-datatype" select="if (* and not(@datatype eq ''))
		then '&rdf;XMLLiteral'
		else if (@datatype) then krextor:curie-to-uri(., @datatype)
		else ()"/>
	    <!-- TODO implement other @datatype cases -->
	</call-template>
    </template>

    <template match="*[@rel and not(@href)]">
	<call-template name="krextor:create-property">
	    <with-param name="property" select="krextor:curies-to-uris(., @rel)"/>
	</call-template>
    </template>

    <template match="*[@rev and not(@href)]">
	<call-template name="krextor:create-property">
	    <with-param name="property" select="krextor:curies-to-uris(., @rev)"/>
	</call-template>
    </template>

    <template match="*[@resource or @href]">
	<variable name="object" select="(@resource|@href)[1]"/>
	<if test="@rel">
	    <call-template name="krextor:add-uri-property">
		<with-param name="property" select="krextor:curies-to-uris(., @rel)"/>
		<with-param name="object" select="$object"/>
	    </call-template>
	</if>
	<if test="@rev">
	    <call-template name="krextor:add-uri-property">
		<with-param name="property" select="krextor:curies-to-uris(., @rev)"/>
		<with-param name="object" select="$object"/>
		<with-param name="inverse" select="true()"/>
	    </call-template>
	</if>
	<if test="not(@rel|@rev)">
	    <call-template name="krextor:add-uri-property">
		<with-param name="object" select="$object"/>
	    </call-template>
	</if>
    </template>
</stylesheet>
