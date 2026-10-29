defmodule GettextSigilsTest.Expansion.Wrapper do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      use GettextSigils,
        backend: GettextSigilsTest.DummyGettext,
        sigils: [domain: "wrapped", modifiers: [m: [context: inspect(__MODULE__)]]]

      @label ~t"label"m
    end
  end
end

defmodule GettextSigilsTest.Expansion.FromAttribute do
  @moduledoc false
  @dom "attr"
  use GettextSigils, backend: GettextSigilsTest.DummyGettext, sigils: [domain: @dom]

  def label, do: ~t"label"
end

defmodule GettextSigilsTest.Expansion do
  @moduledoc false
  use ExUnit.Case, async: true
  use GettextSigilsTest.Expansion.Wrapper

  alias GettextSigilsTest.Expansion.FromAttribute

  test "the sigil resolves its options when used in the block that sets them up" do
    assert @label == "wrapped/GettextSigilsTest.Expansion: label"
  end

  test "options built from an attribute resolve at runtime" do
    assert FromAttribute.label() == "attr: label"
  end

  test "options built from a variable resolve at runtime" do
    # A string, so the formatter cannot hoist the `use` above the assignment.
    [{module, _}] =
      Code.compile_string("""
      defmodule GettextSigilsTest.Expansion.FromVariable do
        dom = "var"
        use GettextSigils, backend: GettextSigilsTest.DummyGettext, sigils: [domain: dom]
        def label, do: ~t"label"
      end
      """)

    assert module.label() == "var: label"
  end

  test "options with string interpolation resolve outside functions" do
    [{module, _}] =
      Code.compile_string("""
      defmodule GettextSigilsTest.Expansion.Interpolated do
        use GettextSigils, backend: GettextSigilsTest.DummyGettext, sigils: [domain: "\#{:interp}"]
        @label ~t"label"
        def label, do: @label
      end
      """)

    assert module.label() == "interp: label"
  end

  test "outside a function, options from attributes raise a clear error" do
    assert_raise CompileError, ~r/needs :sigils options without variables or attributes/, fn ->
      Code.compile_string("""
      defmodule GettextSigilsTest.Expansion.AttributeAtBody do
        @dom "attr"
        use GettextSigils, backend: GettextSigilsTest.DummyGettext, sigils: [domain: @dom]
        @label ~t"label"
      end
      """)
    end
  end

  test "a later use with runtime-only options discards the options stored by an earlier use" do
    assert_raise CompileError, ~r/needs :sigils options without variables or attributes/, fn ->
      Code.compile_string("""
      defmodule GettextSigilsTest.Expansion.StaleOptions do
        use GettextSigils, backend: GettextSigilsTest.DummyGettext, sigils: [domain: "first"]
        @dom "second"
        use GettextSigils, backend: GettextSigilsTest.DummyGettext, sigils: [domain: @dom]
        @label ~t"label"
      end
      """)
    end
  end
end
