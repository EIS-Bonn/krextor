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

<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" 
    xpath-default-namespace="http://www.w3.org/1999/XSL/Transform"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:f="http://fxsl.sf.net/"
    exclude-result-prefixes="krextor xi xs xd"
    version="2.0">

    <import href="../lib/fxsl/f/func-apply.xsl"/>
    <import href="../lib/fxsl/f/func-apply2.xsl"/>
    <import href="../lib/fxsl/f/func-curry.xsl"/>

    <function name="f:return-first">
	<param name="function"/>
	<param name="iterate-params"/>
	<param name="static-params"/>
	<sequence select="f:return-first-step(
	    $function,
	    $iterate-params[1],
	    subsequence($iterate-params, 2),
	    $static-params)"/>
    </function>

    <function name="f:return-first-step">
	<param name="function"/>
	<param name="head"/>
	<param name="tail"/>
	<param name="static-params"/>
	<variable name="result" select="f:apply($function, $head, $static-params)"/>
	<sequence select="if ($result) then $result
	    else if (exists($tail))
	    then f:return-first-step(
		$function,
		$tail[1],
		subsequence($tail, 2),
		$static-params)
	    else ()"/>
    </function>

    <!-- not used at the moment -->
    <function name="f:generate-id" as="element()">
	<f:generate-id/>
    </function>

    <template match="f:generate-id" mode="f:FXSL">
	<param name="arg1"/>
	<sequence select="f:generate-id($arg1)"/>
    </template>

    <function name="f:generate-id">
	<param name="node"/>
	<sequence select="generate-id($node)"/>
    </function>

    <!-- not used at the moment -->
    <function name="f:apply2" as="element()">
	<f:apply2/>
    </function>

    <template match="f:apply2" mode="f:FXSL">
	<param name="arg1"/>
	<param name="arg2"/>
	<sequence select="f:apply2($arg1, $arg2)"/>
    </template>

    <function name="f:apply2" as="element()">
	<param name="pFunc"/>
	<sequence select="f:curry(f:apply2(), 2, $pFunc)"/>
    </function>
</stylesheet>

