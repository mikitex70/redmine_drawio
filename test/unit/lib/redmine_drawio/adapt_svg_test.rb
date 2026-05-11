# frozen_string_literal: true

require 'test_helper'

module RedmineDrawio
  class AdaptSvgTest < ActiveSupport::TestCase

    # Single <script> tag
    def test_removes_single_script_tag
      svg = '<svg><script>alert(1)</script><circle/></svg>'
      result = Macros.adaptSvg(svg, nil)
      assert_not_includes result, 'alert(1)'
    end

    # Multiple <script> tags
    def test_removes_all_script_tags
      svg = '<svg><script>alert(1)</script><script>alert(2)</script></svg>'
      result = Macros.adaptSvg(svg, nil)
      assert_not_includes result, 'alert(1)'
      assert_not_includes result, 'alert(2)'
    end

    # Multiline script block
    def test_removes_multiline_script_tag
      svg = "<svg><script>\nalert(1)\n</script></svg>"
      result = Macros.adaptSvg(svg, nil)
      assert_not_includes result, 'alert(1)'
    end

    # Event handler on root element
    def test_removes_onload_handler
      svg = '<svg onload="alert(1)"><circle/></svg>'
      result = Macros.adaptSvg(svg, nil)
      assert_no_match(/onload/i, result)
      assert_not_includes result, 'alert(1)'
    end

    # Event handler on a child element
    def test_removes_onclick_handler
      svg = '<svg><rect onclick="alert(1)" width="10" height="10"/></svg>'
      result = Macros.adaptSvg(svg, nil)
      assert_no_match(/onclick/i, result)
      assert_not_includes result, 'alert(1)'
    end

    # javascript: URL in href
    def test_neutralizes_javascript_href
      svg = '<svg><a href="javascript:alert(1)">click</a></svg>'
      result = Macros.adaptSvg(svg, nil)
      assert_no_match(/javascript:/i, result)
    end

    # javascript: URL in xlink:href (SVG-specific)
    def test_neutralizes_javascript_xlink_href
      svg = '<svg><a xlink:href="javascript:alert(1)">click</a></svg>'
      result = Macros.adaptSvg(svg, nil)
      assert_no_match(/javascript:/i, result)
    end

    # Safe content must be preserved
    def test_preserves_safe_svg_content
      svg = '<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="40" fill="red"/></svg>'
      result = Macros.adaptSvg(svg, nil)
      assert_includes result, '<circle'
      assert_includes result, 'fill="red"'
    end

  end
end
