require "test_helper"

class RendererTest < NicePartials::Test
  test "render basic nice partial" do
    render("basic") { |p| p.content_for :message, "hello from nice partials" }

    assert_text "hello from nice partials"
  end

  test "render nice partial in card template" do
    render(template: "card_test")

    assert_text "Some Title"
    assert_css "p", class: "text-bold", text: "Lorem Ipsum"
    assert_css("img") { assert_equal "https://example.com/image.jpg", _1["src"] }
  end

  test "render with options from call site" do
    render "columns" do |partial|
      partial.left "The Left", class: "left-column"
      partial.right "The Right", class: "right-column"
    end

    assert_css "div", class: %w[grid gap-2] do
      assert_css "div", id: "left", class: "left-column", text: "The Left", count: 1
      assert_css "div", id: "right", class: "right-column", text: "The Right", count: 1
    end
  end

  test "render without options from call site" do
    render "columns" do |partial|
      partial.left "The Left"
      partial.right "The Right"
    end

    assert_css "div", class: %w[grid gap-2] do
      assert_css "div:not([class])", id: "left", text: "The Left", count: 1
      assert_css "div:not([class])", id: "right", text: "The Right", count: 1
    end
  end

  test "accessing partial in outer context won't leak state to inner render" do
    render "partial_accessed_in_outer_context"

    assert_text "hello"
    assert_text "goodbye"
    assert_css "span", text: ""
    assert_no_text "hellogoodbye"
  end

  test "explicit yield without any arguments auto-captures passed block" do
    render "yields/plain" do |partial, auto_capture_shouldnt_pass_extra_argument|
      assert_kind_of NicePartials::Partial, partial
      assert_nil auto_capture_shouldnt_pass_extra_argument
    end
  end

  test "explicit yield with symbol auto-captures passed block" do
    render "yields/symbol" do |partial, auto_capture_shouldnt_pass_extra_argument|
      assert_kind_of NicePartials::Partial, partial
      assert_nil auto_capture_shouldnt_pass_extra_argument
    end
  end

  test "explicit yield with object won't auto-capture but make partial available in capture" do
    render "yields/object" do |object, partial|
      assert_equal Hash.new(custom_key: :custom_value), object
      assert_kind_of NicePartials::Partial, partial
    end
  end

  test "explicit yield without any arguments with nesting" do
    render "yields/plain_nested" do
      tag.span "Output in outer partial through yield"
    end

    assert_css "span", text: "Output in outer partial through yield"
  end

  test "output_buffer captures content not written via yield/content_for" do
    nice_partial = nil
    render "basic" do |p|
      nice_partial = p
      p.content_for :message, "hello from nice partials"
      "Some extra content"
    end

    assert_text "hello from nice partials"
    assert_equal "Some extra content", nice_partial.yield
  end

  test "mixing Partial#yield call styles renders all captured content" do
    render template: "mixed_yield_test"

    assert_css "#mixed_yield" do
      assert_css "#output_buffer", text: "output buffer content"
      assert_css "#slot", text: "slot content"
    end
  end

  test "mixing Partial#yield call styles with objects renders all captured content" do
    render template: "mixed_yield_with_object_test"

    assert_css "#mixed_yield_with_object" do
      assert_css "#output_buffer", text: "output buffer content"
      assert_css "#yielded_object", text: "slot content"
    end
  end

  test "doesn't clobber Kernel.p" do
    assert_output "\"it's clobbering time\"\n" do
      render("clobberer") { |p| p.content_for :message, "hello from nice partials" }
    end

    assert_text "hello from nice partials"
  end

  test "deprecates top-level access through p method" do
    assert_deprecated /p is deprecated and will be removed from nice_partials \d/, NicePartials::DEPRECATOR do
      assert_output "\"it's clobbering time\"\n" do
        render("clobberer") { |p| p.content_for :message, "hello from nice partials" }
      end
    end
  end
end
