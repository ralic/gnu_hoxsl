<?xml version="1.0" encoding="utf-8"?>
<!--@comment
  Generate boilerplate for dynamic function applications

  Copyright (C) 2014 LoVullo Associates, Inc.

    This file is part of hoxsl.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
-->

<!--
  TODOs:
     - Properly handle arity overloading.
     - Generate functions for partial applications, so long as the target
       function does not have its arity overloaded (since that would
       cause currying and partial application of N>1 arguments to
       potentially yield different results).
-->

<stylesheet version="2.0"
  xmlns="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:f="http://mikegerwitz.com/hoxsl/apply"
  xmlns:_f="http://mikegerwitz.com/hoxsl/apply/_priv"
  xmlns:fgen="http://mikegerwitz.com/hoxsl/apply/gen"
  xmlns:out="http://mikegerwitz.com/hoxsl/apply/gen/_out"
  exclude-result-prefixes="#default fgen">

<import href="../apply/ref.xsl" />

<output indent="yes"
        encoding="utf-8" />

<namespace-alias stylesheet-prefix="out"
                 result-prefix="xsl" />

<!--
  Begin processing of XSLT document

  A document will be output with a generated stylesheet containing the
  boilerplate necessary for dynamically calling each of the functions
  defined therein.
-->
<template match="/xsl:stylesheet|/xsl:transform"
          priority="5">
  <document>
    <comment>
      <text>WARNING: This stylesheet has been generated by </text>
      <text>hoxsl; please do not modify</text>
    </comment>

    <out:stylesheet version="2.0">
      <!-- namespaces might be referenced in strings (e.g. @as), and so may
           not be copied by default -->
      <sequence select="namespace::*[ name() ]" />

      <xsl:apply-templates mode="fgen:create" />
    </out:stylesheet>
  </document>
</template>


<!--
  Refuse to process non-XSLT documents

  Hopefully will help to avoid confusion when accidentally processing
  the wrong file.
-->
<template match="/*"
          priority="1">
  <message terminate="yes">
    <text>fatal: unexpected root node `</text>
    <value-of select="name()" />
    <text>'</text>
  </message>
</template>


<!--
  Skip nullary functions

  Nullary functions (functions that accept no arguments) are either
  thunks or are used purely for their side-effects.  We cannot
  generate a definition for them of the same name, because our
  definitions are nullary;  instead, we expect the caller to take
  caution.

  If a thunk, then the function will always return the same value and
  it does not matter when processing occurs.

  If used for side-effects, then order of processing may matter, but
  this is a dangerous assumption in itself, since some implementations
  may not evaluate the function until its return value is actually used.

  Either way, handle it yourself.
-->
<template mode="fgen:create"
          match="xsl:function[ not( xsl:param ) ]"
          priority="5">
  <comment>
    <text>No definition generated for nullary function `</text>
    <value-of select="@name" />
    <text>'</text>
  </comment>
</template>


<!--
  Do not process functions that are overloaded on arity

  There are a couple reasons for this:  Firstly, overloading is
  fundamentally incompatible with partial application, because we are unable
  to determine when a function is fully applied.  Secondly, we would have no
  choice but to generate functions for every arity that does @emph{not}
  exist.  Together, that would yield a very awkward implementation whereby
  applying N arguments may apply the target function, but N-1 and N+1 may
  result in a partial application.  That is not acceptable.

  To aid in debugging, a comment is output stating that the function was
  explicitly ignored.
-->
<template mode="fgen:create"
          match="xsl:function[
                   @name = root(.)/xsl:*/xsl:function[
                     not( . is current() )
                   ]/@name
                 ]"
          priority="5">
  <comment>
    <text>No definition generated for overloaded function `</text>
    <value-of select="@name" />
    <text>#</text>
    <value-of select="count( xsl:param )" />
    <text>'</text>
  </comment>
</template>


<!--
  Process function definition
-->
<template mode="fgen:create"
          match="xsl:function[ xsl:param ]"
          priority="4">
  <!-- we need to take care with namespacing; let's remove context
       dependencies and simply specify the full namespace URI -->
  <variable name="name-resolv"
            select="resolve-QName( @name, . )" />
  <variable name="ns"
            select="namespace-uri-from-QName( $name-resolv )" />
  <variable name="ns-prefix"
            select="prefix-from-QName( $name-resolv )" />

  <sequence select="fgen:create-func(
                      ., $name-resolv, $ns-prefix, $ns )" />
  <sequence select="fgen:create-tpl(
                      $name-resolv, ., $ns-prefix, $ns )" />
</template>


<!--
  Drop irrelevant nodes

  We do not retain any of the original nodes in the document, as the
  result document is intended to be imported into the original.
-->
<template mode="fgen:create"
          match="*|text()"
          priority="1">
  <!-- must not be very important! -->
</template>


<!--
  Generate dynamic application functions for the application of @var{fnref}.

  The most important function is the nullary, which returns a dynamic
  function reference that can be later used to apply the function.

  Functions are also generated for partial applications: given a target
  function @var{f} of arity @var{α}, functions of arity @math{1<x<α} are
  generated that partially apply @var{f} with @var{x} arguments; this is
  short-hand for invoking @code{f:apply} or @code{f:partial} directly.
-->
<function name="fgen:create-func">
  <param name="fnref"       as="element(xsl:function)" />
  <param name="name-resolv" as="xs:QName" />
  <param name="ns-prefix"   as="xs:string" />
  <param name="ns"          as="xs:anyURI" />

  <variable name="local-name"
            select="substring-after( $fnref/@name, ':' )" />

  <variable name="arity"
            select="count( $fnref/xsl:param )" />

  <variable name="params"
            select="$fnref/xsl:param" />

  <!-- the nullary simply returns a dynamic function reference -->
  <out:function name="{$name-resolv}" as="element()">
    <namespace name="{$ns-prefix}"
               select="$ns" />

    <sequence select="f:make-ref( $name-resolv, $arity )" />
  </out:function>

  <!-- all others perform partial applications -->
  <for-each select="1 to ( $arity - 1 )">
    <variable name="partial-arity"
              select="." />

    <variable name="subparams"
              select="subsequence( $params, 1, $partial-arity )" />

    <out:function name="{$name-resolv}" as="item()+">
      <namespace name="{$ns-prefix}"
                 select="$ns" />

      <variable name="argstr"
                select="_f:argstr-gen( $subparams )" />

      <sequence select="_f:param-gen( $subparams )" />

      <out:sequence select="f:partial(
                              {$name-resolv}(),
                              ({$argstr}) )" />
    </out:function>
  </for-each>
</function>


<!--
  Generate function application template

  This will match on the node associated with the nullary delayed
  application function and apply the original function.

  FIXME: Support for functions overloaded by arity.
-->
<function name="fgen:create-tpl">
  <param name="name-resolv" as="xs:QName" />
  <param name="defn"        as="element(xsl:function)" />
  <param name="ns-prefix"   as="xs:string" />
  <param name="ns"          as="xs:anyURI" />

  <variable name="params" as="element()+"
            select="$defn/xsl:param" />

  <out:template mode="f:apply"
                match="f:ref[ {$name-resolv} ]"
                priority="5">
    <namespace name="{$ns-prefix}"
               select="$ns" />

    <sequence select="_f:param-gen( $params )" />

    <variable name="argstr"
              select="_f:argstr-gen( $params )" />

    <out:sequence select="{$name-resolv}({$argstr})" />
  </out:template>
</function>


<!--
  Given a sequence of XSLT function parameters @var{params}, generate
  enumerated argument @code{<param>}s.

  This is to be used in conjunction with @code{_f:argstr-gen}.
-->
<function name="_f:param-gen" as="element()+">
  <param name="params" as="element()+" />

  <for-each select="$params">
    <xsl:variable name="i"
                  select="position()" />

    <out:param name="arg{$i}">
      <copy-of select="@as" />
    </out:param>
  </for-each>
</function>


<!--
  Given a sequence of XSLT function parameters @var{params}, generate
  a string that, when used in an XPath, represents a list of arguments of a
  function application.

  This is to be used in conjunction with @code{_f:param-gen}.
-->
<function name="_f:argstr-gen" as="xs:string">
  <param name="params" as="element()+" />

  <xsl:variable name="argstr">
    <for-each select="$params">
      <if test="position() gt 1">
        <text>, </text>
      </if>
      <text>$arg</text>
      <value-of select="position()" />
    </for-each>
  </xsl:variable>

  <!-- force to string -->
  <value-of select="string( $argstr )" />
</function>

</stylesheet>
